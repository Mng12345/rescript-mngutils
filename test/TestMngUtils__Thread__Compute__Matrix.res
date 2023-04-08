module Nodejs = MngUtils.Nodejs

type input = int
type result = int

let _ABSOLUTE_PATH = Nodejs.Path.resolve2("./test", "./")
let _MODULE_NAME = "TestMngUtils__Thread__Compute__Matrix"

module InputTransfer = {
  type t = input
  let toBuffer = value => {
    let array = Js.TypedArray2.Uint32Array.fromLength(1)
    array->Js_typed_array2.Uint32Array.unsafe_set(0, value)
    array->Js_typed_array2.Uint32Array.buffer
  }

  let fromBuffer = buffer => {
    let array = buffer->Js.TypedArray2.Uint32Array.fromBuffer
    array->Js_typed_array2.Uint32Array.unsafe_get(0)->Js.Undefined.return
  }
}

module ResultTransfer = {
  type t = result

  let toBuffer = value => {
    let array = Js.TypedArray2.Uint32Array.fromLength(1)
    array->Js_typed_array2.Uint32Array.unsafe_set(0, value)
    array->Js_typed_array2.Uint32Array.buffer
  }

  let fromBuffer = buffer => {
    let array = buffer->Js.TypedArray2.Uint32Array.fromBuffer
    array->Js_typed_array2.Uint32Array.unsafe_get(0)->Js.Undefined.return
  }
}

let compute = input => {
  let timeStart = Js.Date.now()
  let array = Js.TypedArray2.Uint8Array.fromLength(input)
  let array2 = Js.TypedArray2.Uint8Array.fromLength(input)
  let result = ref(0)
  for i in 0 to input - 1 {
    for j in 0 to input - 1 {
      result :=
        array->Js_typed_array2.Uint8Array.unsafe_get(i) *
          array2->Js_typed_array2.Uint8Array.unsafe_get(j)
    }
  }
  let timeEnd = Js.Date.now()
  (timeEnd -. timeStart)->Belt.Float.toInt
}
