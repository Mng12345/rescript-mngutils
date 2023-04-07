module Nodejs = MngUtils.Nodejs

type input = int
type result = string

@live
let _ABSOLUTE_PATH = Nodejs.Path.resolve2("./test", "./")
@live
let _MODULE_NAME = "TestMngUtils__Thread__Compute"

@live
let compute = input => {
  input->Belt.Int.toString
}

module InputTransfer = {
  type t = int
  @live
  let toBuffer = value => {
    let array = Js.TypedArray2.Uint32Array.fromLength(1)
    array->Js.TypedArray2.Uint32Array.unsafe_set(0, value)
    array->Js.TypedArray2.Uint32Array.buffer
  }
  @live
  let fromBuffer = buffer => {
    buffer
    ->Js.TypedArray2.Uint32Array.fromBuffer
    ->Js.TypedArray2.Uint32Array.unsafe_get(0)
    ->Js.Undefined.return
  }
}

module ResultTransfer = {
  type t = string
  @live
  let toBuffer = value => {
    let array = Js.TypedArray2.Uint32Array.fromLength(value->Js.String2.length)
    for i in 0 to value->Js.String2.length - 1 {
      let code = value->Js.String2.codePointAt(i)->Belt.Option.getUnsafe
      array->Js.TypedArray2.Uint32Array.unsafe_set(i, code)
    }
    array->Js.TypedArray2.Uint32Array.buffer
  }

  @live
  let fromBuffer = buffer => {
    let array = buffer->Js.TypedArray2.Uint32Array.fromBuffer
    let codes = []
    array->Js.TypedArray2.Uint32Array.forEach((. item) => codes->Js.Array2.push(item)->ignore)
    Js.String2.fromCharCodeMany(codes)->Js.Undefined.return
  }
}
