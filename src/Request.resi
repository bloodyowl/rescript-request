type blob

type rec responseType<'response> =
  | Text: responseType<string>
  | ArrayBuffer: responseType<Js.TypedArray2.ArrayBuffer.t>
  | Document: responseType<Dom.document>
  | Blob: responseType<blob>
  | Json: responseType<Js.Json.t>
  | JsonAsAny: responseType<'response>

type error = [#NetworkRequestFailed | #Timeout]

type method = [#GET | #POST | #OPTIONS | #PATCH | #PUT | #DELETE]

type xhr
external asXhr: 'a => xhr = "%identity"

type response<'a> = {
  status: int,
  ok: bool,
  response: option<'a>,
  xhr: xhr,
}

type progressEvent = {
  lengthComputable: bool,
  loaded: float,
  total: float,
  target: {.},
}

let make: (
  ~url: string,
  ~method: method=?,
  ~responseType: responseType<'payload>,
  ~body: 'body=?,
  ~headers: Js.Dict.t<string>=?,
  ~withCredentials: bool=?,
  ~onLoadStart: progressEvent => unit=?,
  ~onProgress: progressEvent => unit=?,
  ~timeout: int=?,
  unit,
) => Future.t<result<response<'payload>, error>>
