# Request

> ReScript wrapper for XMLHttpRequest

## Installation

Run the following in your console:

```console
$ yarn add rescript-future rescript-request
```

Then add `rescript-request` and `rescript-future` to your `bsconfig.json`'s `bs-dependencies`:

```diff
 {
   "bs-dependencies": [
+    "rescript-request",
+    "rescript-future
   ]
 }
```

## Basics

`Request.make` performs a request and returns a [`Future.t`](https://github.com/bloodyowl/rescript-future) containing a `result<response, error>`.

```reason
Request.make(~url="/api/health", ~responseType=Text, ())
  ->Future.get(Js.log)
// Ok({
//   status: 200,
//   ok: true,
//   response: "{\"ok\":true}",
// })

Request.make(~url="/api/health", ~responseType=Text, ())
  ->Future.get(Js.log)
// Error(#NetworkError)

Request.make(~url="/api/health",  ~responseType=Text, ~timeout=10, ())
  ->Future.get(Js.log)
// Error(#Timeout)

Request.make(~url="/api/health", ~responseType=Json, ())
  ->Future.get(Js.log)
// Ok({
//   status: 200,
//   ok: true,
//   response: {"ok":true},
// })

type response = {"ok": bool}

Request.make(
  ~url="/api/health",
  ~responseType=(JsonAsAny: Request.responseType<response>),
  ()
)
  ->Future.get(Js.log)
// Ok({
//   status: 200,
//   ok: true,
//   response: {"ok":true},
// })
```

## Parameters

- `url`: string,
- `method`: `#GET` (default), `#POST`, `#OPTIONS`, `#PATCH`, `#PUT` or `#DELETE`
- `responseType`:
  - `Text`: (default) response will be `string`
  - `ArrayBuffer`: response will be `Js.TypedArray2.ArrayBuffer.t`
  - `Document`: response will be `Dom.document`
  - `Blob`: response will be `Request.blob`
  - `Json`: response will be `Js.Json.t`
  - `JsonAsAny`: response will be any, use with `(JsonAsAny: Request.responseType<yourType>)`
- `body`: any
- `headers`: `Js.Dict` containing the headers
- `withCredentials`: bool
- `onLoadStart`
- `onProgress`
- `timeout`: int

### Response

The response is a record containing:

- `status`: `int`
- `ok`: `bool`
- `response`: the decoded response, which is an `option`

### Errors

- `#NetworkRequestFailed`
- `#Timeout`

### Mapping errors to your own type

You can map the `Request.error` types to your own:

```reason
type error =
  | Empty
  | NetworkError
  | Timeout

let mapError = error => {
  switch error {
  | #NetworkRequestFailed => NetworkError
  | #Timeout => Timeout
  }
}

let emptyToError = ({Request.response: response}) => {
  switch response {
  | None => Error(Empty)
  | Some(value) => Ok(value)
  }
}

let requestApi = (~url, ~responseType) => {
  Request.make(~url, ~responseType, ())
  ->Future.mapError(~propagateCancel=true, mapError)
  ->Future.mapResult(~propagateCancel=true, emptyToError)
}
```

> Don't forget to the use the `propagateCancel` option so that calling `Future.cancel` on the `requestApi` return value aborts the request!
