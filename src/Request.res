type blob

type rec responseType<'response> =
  | Text: responseType<string>
  | ArrayBuffer: responseType<Js.TypedArray2.ArrayBuffer.t>
  | Document: responseType<Dom.document>
  | Blob: responseType<blob>
  | Json: responseType<Js.Json.t>
  | JsonAsAny: responseType<'response>

type method = [#GET | #POST | #OPTIONS | #PATCH | #PUT | #DELETE]

type error = [#NetworkRequestFailed | #Timeout]

type progressEvent = {
  lengthComputable: bool,
  loaded: float,
  total: float,
  target: {.},
}

module XMLHttpRequest = {
  type t<'input, 'responseType>
  @bs.new external make: unit => t<'input, 'responseType> = "XMLHttpRequest"
  @bs.send
  external \"open": (t<'input, 'responseType>, method, string, @bs.as(json`true`) _) => unit =
    "open"
  @bs.set
  external setResponseType: (t<'input, 'responseType>, string) => unit = "responseType"
  @bs.set
  external setTimeout: (t<'input, 'responseType>, int) => unit = "timeout"
  @bs.send
  external setRequestHeader: (t<'input, 'responseType>, string, string) => unit = "setRequestHeader"
  @bs.send external send: (t<'input, 'responseType>, 'input) => unit = "send"
  @bs.send external abort: t<'input, 'responseType> => unit = "abort"
  @bs.get external status: t<'input, 'responseType> => int = "status"
  @bs.get external responseText: t<'input, 'responseType> => string = "responseText"
  @bs.get
  external response: t<'input, 'responseType> => Js.Nullable.t<'responseType> = "response"
  @bs.send
  external addLoadEventListener: (
    t<'input, 'responseType>,
    @bs.as("load") _,
    unit => unit,
  ) => unit = "addEventListener"
  @bs.send
  external removeLoadEventListener: (
    t<'input, 'responseType>,
    @bs.as("load") _,
    unit => unit,
  ) => unit = "removeEventListener"
  @bs.send
  external addErrorEventListener: (
    t<'input, 'responseType>,
    @bs.as("error") _,
    unit => unit,
  ) => unit = "addEventListener"
  @bs.send
  external removeErrorEventListener: (
    t<'input, 'responseType>,
    @bs.as("error") _,
    unit => unit,
  ) => unit = "removeEventListener"

  @bs.send
  external addTimeoutEventListener: (
    t<'input, 'responseType>,
    @bs.as("timeout") _,
    unit => unit,
  ) => unit = "addEventListener"
  @bs.send
  external removeTimeoutEventListener: (
    t<'input, 'responseType>,
    @bs.as("timeout") _,
    unit => unit,
  ) => unit = "removeEventListener"

  @bs.send
  external addLoadStartEventListener: (
    t<'input, 'responseType>,
    @bs.as("loadstart") _,
    progressEvent => unit,
  ) => unit = "addEventListener"
  @bs.send
  external removeLoadStartEventListener: (
    t<'input, 'responseType>,
    @bs.as("loadstart") _,
    progressEvent => unit,
  ) => unit = "removeEventListener"

  @bs.send
  external addProgressEventListener: (
    t<'input, 'responseType>,
    @bs.as("progress") _,
    progressEvent => unit,
  ) => unit = "addEventListener"
  @bs.send
  external removeProgressEventListener: (
    t<'input, 'responseType>,
    @bs.as("progress") _,
    progressEvent => unit,
  ) => unit = "removeEventListener"

  @bs.set
  external setWithCredentials: (t<'input, 'responseType>, bool) => unit = "withCredentials"
}

type xhr
external asXhr: 'a => xhr = "%identity"

type response<'a> = {
  status: int,
  ok: bool,
  response: option<'a>,
  xhr: xhr,
}

let make = (
  type payload body,
  ~url: string,
  ~method: method=#GET,
  ~responseType: responseType<payload>,
  ~body: option<body>=?,
  ~headers: option<Js.Dict.t<string>>=?,
  ~withCredentials=false,
  ~onLoadStart=?,
  ~onProgress=?,
  ~timeout: option<int>=?,
  (),
): Future.t<result<response<payload>, error>> => {
  Future.make(resolve => {
    open XMLHttpRequest
    let xhr: t<option<body>, payload> = make()
    xhr->setWithCredentials(withCredentials)
    xhr->\"open"(method, url)
    // Let's not allow synchronous calls
    // That conditions the returned type using a GADT
    xhr->setResponseType(
      switch responseType {
      | Text => ""
      | ArrayBuffer => "arraybuffer"
      | Document => "document"
      | Blob => "blob"
      | Json => "json"
      | JsonAsAny => "json"
      },
    )
    switch timeout {
    | Some(timeout) => xhr->setTimeout(timeout)
    | None => ()
    }
    switch headers {
    | Some(headers) => headers->Js.Dict.entries->Js.Array2.forEach(((key, value)) => {
        xhr->setRequestHeader(key, value)
      })
    | None => ()
    }
    let rec errorListener = () => {
      cleanupEvents()
      resolve(Error(#NetworkRequestFailed))
    }
    and timeoutListener = () => {
      cleanupEvents()
      resolve(Error(#Timeout))
    }
    and loadStartListener = event => {
      switch onLoadStart {
      | Some(onLoadStart) => onLoadStart(event)
      | None => ()
      }
    }
    and progressListener = event => {
      switch onProgress {
      | Some(onProgress) => onProgress(event)
      | None => ()
      }
    }
    and loadListener = () => {
      cleanupEvents()
      let status = xhr->status
      let response = xhr->response->Js.Nullable.toOption
      // Internet Explorer has a bug on the JSON type
      let response: option<payload> = switch (responseType, response) {
      | (Json, Some(response)) when Js.typeof(response) == "string" =>
        try {
          Some(Js.Json.parseExn(xhr->responseText)->Obj.magic)
        } catch {
        | _ => None
        }
      | (JsonAsAny, Some(response)) when Js.typeof(response) == "string" =>
        try {
          Some(Js.Json.parseExn(xhr->responseText)->Obj.magic)
        } catch {
        | _ => None
        }
      | _ => response
      }
      resolve(
        Ok({
          status: status,
          ok: status >= 200 && status < 300,
          response: response,
          xhr: xhr->asXhr,
        }),
      )
    }
    and cleanupEvents = () => {
      xhr->removeErrorEventListener(errorListener)
      xhr->removeLoadEventListener(loadListener)
      xhr->removeTimeoutEventListener(timeoutListener)
      xhr->removeLoadStartEventListener(loadStartListener)
      xhr->removeProgressEventListener(progressListener)
    }
    xhr->addLoadEventListener(loadListener)
    xhr->addErrorEventListener(errorListener)
    xhr->addTimeoutEventListener(timeoutListener)
    xhr->addLoadStartEventListener(loadStartListener)
    xhr->addProgressEventListener(progressListener)
    xhr->send(body)
    Some(
      () => {
        cleanupEvents()
        xhr->abort
      },
    )
  })
}
