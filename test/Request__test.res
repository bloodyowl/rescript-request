open Test

type payload = {"ok": bool}

let isFalse = a => assertion(~operator="isFalse", (a, b) => a == b, a, false)
let isTrue = a => assertion(~operator="isTrue", (a, b) => a == b, a, true)
let intEquals = (a: int, b: int) => assertion(~operator="intEquals", (a, b) => a == b, a, b)
let optionEquals = (a, b) =>
  assertion(~operator="optionEquals", (a, b) => Belt.Option.eq(a, b, (a, b) => a == b), a, b)

testAsync("request", callback => {
  let _ =
    Request.make(~url="data:text/plain,hello!", ~responseType=Text, ())->Future.get(response => {
      switch response {
      | Ok({status, ok, response}) =>
        intEquals(status, 200)
        isTrue(ok)
        optionEquals(response, Some("hello!"))
        callback()
      | Error(error) =>
        Js.log(error)
        isFalse(true)
        callback()
      }
    })
})

external asJson: 'a => Js.Json.t = "%identity"

testAsync("request json", callback => {
  let _ =
    Request.make(
      ~url="data:text/json,{\"ok\":true}",
      ~responseType=Json,
      (),
    )->Future.get(response => {
      switch response {
      | Ok({status, ok, response}) =>
        intEquals(status, 200)
        isTrue(ok)
        optionEquals(response, Some(asJson({"ok": true})))
        callback()
      | Error(error) =>
        Js.log(error)
        isFalse(true)
        callback()
      }
    })
})

testAsync("request json as any", callback => {
  let _ =
    Request.make(
      ~url="data:text/json,{\"ok\":true}",
      ~responseType=(JsonAsAny: Request.responseType<payload>),
      (),
    )->Future.get(response => {
      switch response {
      | Ok({status, ok, response}) =>
        intEquals(status, 200)
        isTrue(ok)
        optionEquals(response, Some({"ok": true}))
        callback()
      | Error(error) =>
        Js.log(error)
        isFalse(true)
        callback()
      }
    })
})

testAsync("request json that doesn't parse", callback => {
  let _ =
    Request.make(
      ~url="data:text/json,{\"ok\":unknown}",
      ~responseType=(JsonAsAny: Request.responseType<payload>),
      (),
    )->Future.get(response => {
      switch response {
      | Ok({status, ok, response}) =>
        intEquals(status, 200)
        isTrue(ok)
        optionEquals(response, None)
        callback()
      | Error(error) =>
        Js.log(error)
        isFalse(true)
        callback()
      }
    })
})
