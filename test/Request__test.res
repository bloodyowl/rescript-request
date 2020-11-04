open TestFramework

type payload = {"ok": bool}

describe("Request", ({testAsync}) => {
  testAsync("request", ({expect, callback}) => {
    let _ =
      Request.make(~url="data:text/plain,hello!", ~responseType=Text, ())->Future.get(response => {
        switch response {
        | Ok({status, ok, response}) =>
          expect.int(status).toBe(200)
          expect.bool(ok).toBeTrue()
          expect.value(response).toEqual(Some("hello!"))
          callback()
        | Error(error) =>
          Js.log(error)
          expect.bool(true).toBeFalse()
          callback()
        }
      })
  })

  testAsync("request json", ({expect, callback}) => {
    let _ =
      Request.make(
        ~url="data:text/json,{\"ok\":true}",
        ~responseType=Json,
        (),
      )->Future.get(response => {
        switch response {
        | Ok({status, ok, response}) =>
          expect.int(status).toBe(200)
          expect.bool(ok).toBeTrue()
          expect.value(response).toEqual({"ok": true}->Obj.magic)
          callback()
        | Error(error) =>
          Js.log(error)
          expect.bool(true).toBeFalse()
          callback()
        }
      })
  })

  testAsync("request json as any", ({expect, callback}) => {
    let _ =
      Request.make(
        ~url="data:text/json,{\"ok\":true}",
        ~responseType=(JsonAsAny: Request.responseType<payload>),
        (),
      )->Future.get(response => {
        switch response {
        | Ok({status, ok, response}) =>
          expect.int(status).toBe(200)
          expect.bool(ok).toBeTrue()
          expect.value(response).toEqual(Some({"ok": true}))
          callback()
        | Error(error) =>
          Js.log(error)
          expect.bool(true).toBeFalse()
          callback()
        }
      })
  })

  testAsync("request json that doesn't parse", ({expect, callback}) => {
    let _ =
      Request.make(
        ~url="data:text/json,{\"ok\":unknown}",
        ~responseType=(JsonAsAny: Request.responseType<payload>),
        (),
      )->Future.get(response => {
        switch response {
        | Ok({status, ok, response}) =>
          expect.int(status).toBe(200)
          expect.bool(ok).toBeTrue()
          expect.value(response).toEqual(None)
          callback()
        | Error(error) =>
          Js.log(error)
          expect.bool(true).toBeFalse()
          callback()
        }
      })
  })
})
