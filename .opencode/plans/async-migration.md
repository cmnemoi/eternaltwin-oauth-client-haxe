# Plan : Migration synchrone → asynchrone avec tink_core

## Diagnostic

Toute la chaîne HTTP est synchrone, y compris la version JavaScript :

| Fichier | Ligne | Problème |
|---|---|---|
| `src/eternaltwin/oauth/HttpClient.hx` | 28-32 | `post()` retourne `HttpResponse` directement (synchrone) |
| `src/eternaltwin/oauth/JsHttpClient.hx` | 47 | `http.async = false` force le XHR synchrone (déprécié dans les navigateurs modernes) |
| `src/eternaltwin/oauth/SysHttpClient.hx` | 76 | `http.request(true)` est bloquant |
| `src/eternaltwin/oauth/RfcOauthClient.hx` | 79 | `httpClient.post(...)` attend un retour synchrone |
| `tests/eternaltwin/oauth/FakeHttpClient.hx` | 47-56 | Le fake retourne `HttpResponse` directement |

Le XHR synchrone est déprécié dans les navigateurs et bloque l'event loop en Node.js.

## Solution

Utiliser `tink_core` pour rendre toute la chaîne asynchrone sur toutes les plateformes :

- **`Future<T>`** pour la couche HTTP (`HttpClient.post()` → `Future<HttpResponse>`)
- **`Promise<T>`** (alias de `Future<Outcome<T, Error>>`) pour la couche métier (`getAccessToken()` → `Promise<AccessToken>`), car cette opération peut échouer (erreur HTTP, JSON malformé)
- **`OauthError`** est conservé tel quel et wrappé dans `tink.core.Error` via `Error.withData(code, message, oauthError)` pour transporter l'erreur domain-specific

### Types tink_core utilisés

| Type | Usage | Description |
|---|---|---|
| `Future<T>` | `HttpClient.post()` | Résultat async, pas de notion d'erreur |
| `Future.sync(value)` | `FakeHttpClient`, `SysHttpClient` | Future déjà résolu (sync wrappé) |
| `FutureTrigger<T>` | `JsHttpClient` | Résoudre un Future manuellement depuis des callbacks |
| `Promise<T>` | `RfcOauthClient.getAccessToken()` | Future + gestion d'erreur via `Outcome<T, Error>` |
| `tink.core.Error` | Erreurs dans `RfcOauthClient` | Wrapper autour de `OauthError` via le champ `data` |

## Étapes (TDD)

### Étape 1 : Ajouter `tink_core` comme dépendance

**Fichiers à modifier :**
- `haxelib.json` : ajouter `"tink_core": ""` dans `dependencies`
- `build.hxml` : ajouter `-lib tink_core`
- `test.hxml` : ajouter `-lib tink_core`
- `test-js.hxml` : ajouter `-lib tink_core`
- `test-neko.hxml` : ajouter `-lib tink_core`

**Vérification :** `haxe test.hxml` compile sans erreur.

---

### Étape 2 : Modifier l'interface `HttpClient`

**Fichier :** `src/eternaltwin/oauth/HttpClient.hx`

**Changement de signature :**
```haxe
// Avant
function post(url:String, headers:Map<String, String>, body:String):HttpResponse;

// Après
function post(url:String, headers:Map<String, String>, body:String):Future<HttpResponse>;
```

**Import à ajouter :** `import tink.core.Future;`

**Note :** Cette modification va casser la compilation de tous les fichiers implémentant `HttpClient`. C'est attendu — les étapes suivantes corrigent ça.

---

### Étape 3 : Adapter `FakeHttpClient` (tests)

**Fichier :** `tests/eternaltwin/oauth/FakeHttpClient.hx`

**Changement :**
```haxe
// Avant
public function post(...):HttpResponse {
    // ...
    return cannedResponse;
}

// Après
public function post(...):Future<HttpResponse> {
    // ...
    return Future.sync(cannedResponse);
}
```

**Import à ajouter :** `import tink.core.Future;`

**Pourquoi `Future.sync()` :** Le fake n'a pas besoin d'être réellement asynchrone. `Future.sync()` crée un Future déjà résolu, ce qui garde les tests simples et déterministes.

---

### Étape 4 : Adapter `RfcOauthClient.getAccessToken()` → `Promise<AccessToken>`

**Fichier :** `src/eternaltwin/oauth/RfcOauthClient.hx`

**Changement de signature :**
```haxe
// Avant
public function getAccessToken(code:String):AccessToken {
    var headers = buildTokenRequestHeaders();
    var body = buildTokenRequestBody(code);
    var response = httpClient.post(config.tokenEndpoint, headers, body);
    validateResponse(response);
    return parseTokenResponse(response.body);
}

// Après
public function getAccessToken(code:String):Promise<AccessToken> {
    var headers = buildTokenRequestHeaders();
    var body = buildTokenRequestBody(code);
    return httpClient.post(config.tokenEndpoint, headers, body)
        .next(function(response:HttpResponse):Promise<AccessToken> {
            return validateAndParse(response);
        });
}

private function validateAndParse(response:HttpResponse):Promise<AccessToken> {
    var isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccess) {
        var oauthError = new OauthError(
            "Token request failed with status " + response.statusCode + ": " + response.body
        );
        return Promise.reject(
            Error.withData(cast response.statusCode, oauthError.message, oauthError)
        );
    }
    try {
        return Promise.resolve(AccessToken.fromJson(response.body));
    } catch (error:Dynamic) {
        var oauthError = new OauthError("Failed to parse token response: " + response.body);
        return Promise.reject(
            Error.withData(InternalError, oauthError.message, oauthError)
        );
    }
}
```

**Imports à ajouter :**
- `import tink.core.Promise;`
- `import tink.core.Error;` (ou `tink.core.Error.ErrorCode`)

**Notes :**
- `getAuthorizationUri()` reste synchrone — c'est une pure construction d'URL sans I/O
- `OauthError` est wrappé dans `tink.core.Error` via `Error.withData()` pour conserver l'erreur domain-specific dans le champ `data`
- Le `ErrorCode` HTTP de tink correspond aux codes HTTP standards (401 = `Unauthorized`, etc.), on peut donc caster le statusCode directement
- `next()` sur un `Future<HttpResponse>` permet de retourner un `Promise<AccessToken>` (transformation qui peut échouer)

---

### Étape 5 : Adapter les tests `RfcOauthClientTest`

**Fichier :** `tests/eternaltwin/oauth/RfcOauthClientTest.hx`

Les tests qui appellent `getAccessToken()` doivent devenir asynchrones.
`utest` supporte les tests async via un paramètre `async:utest.Async`.

**Exemple — test de succès :**
```haxe
// Avant
function testShouldExchangeCodeForAccessToken():Void {
    var accessToken = oauthClient.getAccessToken("one_time_auth_code");
    thenAccessTokenIsParsedCorrectly(accessToken);
}

// Après
function testShouldExchangeCodeForAccessToken(async:utest.Async):Void {
    oauthClient.getAccessToken("one_time_auth_code")
        .handle(function(outcome) {
            switch (outcome) {
                case Success(accessToken):
                    thenAccessTokenIsParsedCorrectly(accessToken);
                case Failure(error):
                    Assert.fail("Expected success but got: " + error.message);
            }
            async.done();
        });
}
```

**Exemple — test d'erreur (remplace `Assert.raises()`) :**
```haxe
// Avant
function testShouldThrowOnNonSuccessHttpStatus():Void {
    var errorClient = givenFakeHttpClientWithErrorResponse();
    var client = givenOauthClient(errorClient);

    Assert.raises(function() {
        client.getAccessToken("one_time_auth_code");
    }, OauthError);
}

// Après
function testShouldThrowOnNonSuccessHttpStatus(async:utest.Async):Void {
    var errorClient = givenFakeHttpClientWithErrorResponse();
    var client = givenOauthClient(errorClient);

    client.getAccessToken("one_time_auth_code")
        .handle(function(outcome) {
            switch (outcome) {
                case Failure(error):
                    Assert.isTrue(Std.isOfType(error.data, OauthError));
                case Success(_):
                    Assert.fail("Expected failure but got success");
            }
            async.done();
        });
}
```

**Tests à migrer vers async (ceux qui appellent `getAccessToken()`) :**
- `testShouldExchangeCodeForAccessToken`
- `testShouldSendBasicAuthHeader`
- `testShouldSendCorrectJsonBody`
- `testShouldPostToTokenEndpoint`
- `testShouldThrowOnNonSuccessHttpStatus`
- `testShouldThrowOnMalformedJsonResponse`

**Tests qui restent inchangés (pas d'I/O) :**
- `testShouldBuildAuthorizationUri`
- `testShouldUrlEncodeSpecialCharacters`

**Import à ajouter :** `import tink.core.Outcome;`

---

### Étape 6 : Adapter `JsHttpClient`

**Fichier :** `src/eternaltwin/oauth/JsHttpClient.hx`

**Changement clé :** Passer de XHR synchrone à asynchrone via `FutureTrigger`.

```haxe
// Avant
private function createRequest(...):HttpJs {
    var http = new HttpJs(url);
    http.async = false;  // ← PROBLÈME
    // ...
}

private function executeRequest(http:HttpJs):HttpResponse {
    // ...
    http.request(true);
    return new HttpResponse(statusCode, responseBody);
}

// Après
private function createRequest(...):HttpJs {
    var http = new HttpJs(url);
    http.async = true;  // ← CORRIGÉ
    // ...
}

private function executeRequest(http:HttpJs):Future<HttpResponse> {
    var trigger = Future.trigger();
    var statusCode:Int = 0;

    http.onStatus = function(status:Int):Void {
        statusCode = status;
    };
    http.onData = function(data:String):Void {
        trigger.trigger(new HttpResponse(statusCode, data));
    };
    http.onError = function(error:String):Void {
        trigger.trigger(new HttpResponse(statusCode, error));
    };

    http.request(true);
    return trigger.asFuture();
}
```

**Import à ajouter :** `import tink.core.Future;`

**Note :** `onStatus` est appelé avant `onData`/`onError` par le XHR, donc on peut capturer le statusCode avant de résoudre le trigger.

---

### Étape 7 : Adapter `SysHttpClient`

**Fichier :** `src/eternaltwin/oauth/SysHttpClient.hx`

`sys.Http.request()` est intrinsèquement bloquant sur les targets sys. On enveloppe simplement le résultat dans `Future.sync()`.

```haxe
// Avant
private function executeRequest(http:Http):HttpResponse {
    // ...
    http.request(true);
    return new HttpResponse(statusCode, responseBody);
}

// Après
private function executeRequest(http:Http):Future<HttpResponse> {
    // ...
    http.request(true);
    return Future.sync(new HttpResponse(statusCode, responseBody));
}
```

**Import à ajouter :** `import tink.core.Future;`

**Note :** Sur les targets sys, l'appel reste bloquant en pratique mais l'interface est cohérente. C'est le comportement attendu pour Neko/CPP/Python.

---

### Étape 8 : Mettre à jour la documentation

**Fichiers à modifier :**
- Docstrings dans `HttpClient.hx`, `JsHttpClient.hx`, `SysHttpClient.hx`, `RfcOauthClient.hx`
- `README.md` si des exemples d'utilisation existent

**Changements :**
- Mettre à jour les `Returns` dans les docstrings :
  - `HttpClient.post()` : `HttpResponse` → `Future<HttpResponse>`
  - `RfcOauthClient.getAccessToken()` : `AccessToken` → `Promise<AccessToken>`
  - Supprimer la mention `Throws OauthError` et la remplacer par `Returns Failure(Error)` avec `error.data` contenant l'`OauthError`
- Mentionner que `JsHttpClient` est maintenant asynchrone (non-bloquant)
- Mentionner que `SysHttpClient` est synchrone enveloppé dans un Future

---

## Ordre d'exécution TDD

Pour chaque étape, suivre le cycle :
1. Écrire/modifier un test qui échoue
2. Écrire le code minimum pour faire passer le test
3. Refactorer
4. Vérifier que tous les tests passent

**Commandes de vérification :**
```bash
haxe test.hxml        # Tests interp (rapide)
haxe test-js.hxml && node bin/tests.js   # Tests JS
haxe test-neko.hxml && neko bin/tests.n   # Tests Neko
```

## Risques et points d'attention

1. **Compatibilité interp** : Vérifier que `tink_core` fonctionne bien en mode `--interp`.
2. **Breaking change** : Les signatures publiques de `HttpClient.post()` et `RfcOauthClient.getAccessToken()` changent. C'est un breaking change → incrémenter la version majeure (semver 1.x → 2.0.0).
3. **OauthError wrappé** : Les consommateurs qui faisaient `catch (e:OauthError)` devront maintenant faire un pattern match sur `Failure(error)` et accéder à `error.data` pour récupérer l'`OauthError`. C'est un changement d'API à documenter.
4. **statusCode dans JsHttpClient** : Avec le XHR async, les variables locales `statusCode` doivent être capturées correctement dans les closures `onStatus`/`onData`/`onError`. S'assurer que `onStatus` est bien appelé avant `onData`/`onError`.
