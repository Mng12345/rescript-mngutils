let uid = () => {
  `${Js.Math.random()->Belt.Float.toString}-${Js.Math.random()->Belt.Float.toString}-${Js.Math.random()->Belt.Float.toString}-${Js.Math.random()->Belt.Float.toString}`->Js.String2.replaceByRe(
    %re("/\./g"),
    "",
  )
}
