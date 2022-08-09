Test.test("MngUtils_Dayjs", () => {
  let date = MngUtils.Dayjs.dayjsWithString("2022/08/09")
  Js.log2(`date: `, date->MngUtils.Dayjs.format("YYYY-MM-DD"))
})
