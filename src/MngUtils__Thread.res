module Internals = {
  module Nodejs = MngUtils__Nodejs
  module Uid = MngUtils__Uid

  module type Transfer = {
    type t
    let toBuffer: t => Js.TypedArray2.ArrayBuffer.t
    let fromBuffer: Js.TypedArray2.ArrayBuffer.t => Js.Undefined.t<t>
  }

  let _THREAD_SUFFIX = ".thread.js"
  let _MODULE_SUFFIX = ".bs.js"

  let isAbsolutePath = path => {
    path->Js.String2.startsWith("/") || {
        let path = path->Js.String2.toLowerCase
        path->Js.String2.startsWith("c:") ||
        path->Js.String2.startsWith("d:") ||
        path->Js.String2.startsWith("e:") ||
        path->Js.String2.startsWith("f:") ||
        path->Js.String2.startsWith("g:") ||
        path->Js.String2.startsWith("h:") ||
        path->Js.String2.startsWith("i:") ||
        path->Js.String2.startsWith("j:") ||
        path->Js.String2.startsWith("k:") ||
        path->Js.String2.startsWith("l:") ||
        path->Js.String2.startsWith("m:")
      }
  }
  let cleanTempThreadFiles = async (absolutePath, moduleName) => {
    let files = await absolutePath->Nodejs.Fs.readdir
    files->Belt.Array.forEach(file => {
      if file->Js.String2.startsWith(moduleName) && file->Js.String2.endsWith(_THREAD_SUFFIX) {
        let path = Nodejs.Path.resolve2(absolutePath, file)
        Nodejs.Fs.rm(path)
        ->Promise.catch(err => {
          Js.log2(`error: `, err)
          Promise.resolve()
        })
        ->ignore
      }
    })
  }

  let isComputeModuleExists = async (path, name) => {
    let path = Nodejs.Path.resolve2(path, name ++ ".res")
    try {
      (await Nodejs.Fs.stat(path))->ignore
      true
    } catch {
    | _exn => false
    }
  }

  // generate thread.js and return the file path
  let generateParallelMapThread = async (path, name, suffix) => {
    let worker = `
      const { resolve } = require('path') 
      const Compute = require(resolve('${path}', '${name}${suffix}'))
      const { Worker, isMainThread, parentPort, workerData, MessageChannel } = require('worker_threads')
      if (isMainThread) {
        module.exports = function execute(data, parallel) {
          if (!(data instanceof Array)) {
            throw new Error('only support array data.')
          }
          return new Promise((resolve, reject) => {
            const workerMap = new Map()
            const cursor = {value: 0}
            const terminatedCount = {value: 0}
            const result = []
            // record the index info for current worker
            const executeMap = new Map()
            for (let i=0; i<parallel; i++) {
              const worker = new Worker(__filename)
              workerMap.set(worker.threadId, worker)
              worker.on('message', message => {
                if (!message?.action) {
                  throw new Error('the message should contains action field')
                }
                const distributeData = () => {
                  if (cursor.value >= data.length) {
                    // shutdown the worker
                    worker.terminate()
                    terminatedCount.value++
                    if (terminatedCount.value >= parallel) {
                      // sort the result
                      const rawResult = result.sort((item1, item2) => item1.index - item2.index)
                        .map(item => item.data)
                      resolve(rawResult)
                    }
                  } else {
                    const data_ = data[cursor.value++]
                    executeMap.set(worker.threadId, cursor.value - 1)
                    // make data into buffer
                    const buffer = Compute.InputTransfer.toBuffer(data_)
                    worker.postMessage(buffer, [buffer])
                  }
                }
                switch (message.action) {
                  case 'distribute-data-for-me': {
                    distributeData()
                    break
                  }
                  case 'error': {
                    console.log('error in worker(' + worker.threadId + '), message:\\n' + message.message)
                    distributeData()
                    break
                  }
                  case 'current-task-execute-done': {
                    const index = executeMap.get(worker.threadId)
                    if (index === undefined) {
                      throw new Error('can not find the index of current worker(' + worker.threadId + ')')
                    }
                    result.push({
                      index,
                      data: Compute.ResultTransfer.fromBuffer(message.data)
                    })
                    break
                  }
                  default: {
                    throw new Error('unknown action(' + message.action + ')')
                  }
                }
              })
            }
          })
        }
      } else {
        // emit 'distribute-data-for-me' event
        parentPort.postMessage({
          action: 'distribute-data-for-me'
        })  
        parentPort.on('message', buffer => {
          if (!(buffer instanceof ArrayBuffer)) {
            parentPort.postMessage({
              action: 'error',
              message: 'data sent from main thread should be ArrayBuffer.'
            })
          } else {
            try {
              const input = Compute.InputTransfer.fromBuffer(buffer)
              const result = Compute.compute(input)
              const resultBuffer = Compute.ResultTransfer.toBuffer(result)
              parentPort.postMessage({
                action: 'current-task-execute-done',
                data: resultBuffer
              }, [resultBuffer])
              parentPort.postMessage({
                action: 'distribute-data-for-me',
              })
            } catch (err) {
              parentPort.postMessage({
                action: 'error',
                message: String(err)
              })
            }
          }
        })
      }
    `
    let executedFilePath = Nodejs.Path.resolve2(path, `${name}.${Uid.uid()}${_THREAD_SUFFIX}`)
    // create worker
    await Nodejs.Fs.writeFile(
      executedFilePath,
      worker,
      {
        "flag": "w",
      },
    )
    executedFilePath
  }

  let executeParallelMap = (type input result, data: array<input>, parallel, path) => {
    let execute: (array<input>, int, string) => Promise.t<array<result>> = %raw(`
    async function exec(data, parallel, path) {
      const execute = require(path)
      return await execute(data, parallel)
    }
    `)
    execute(data, parallel, path)
  }
}

module type Compute = {
  type input
  type result

  module InputTransfer: Internals.Transfer with type t = input
  module ResultTransfer: Internals.Transfer with type t = result
  // the raw file module name
  let _MODULE_NAME: string
  // the absolute path of file module, eg: /home/workers/
  let _ABSOLUTE_PATH: string

  let compute: input => result
}

let run = async (
  type input result,
  array,
  compute: module(Compute with type input = input and type result = result),
  parallel: int,
): array<result> => {
  module Compute = unpack(compute)
  if !Internals.isAbsolutePath(Compute._ABSOLUTE_PATH) {
    Js.Exn.raiseError(
      `The _ABSOLUTE_PATH(${Compute._ABSOLUTE_PATH}) of module Compute must be absolute.`,
    )
  }
  if !(await Internals.isComputeModuleExists(Compute._ABSOLUTE_PATH, Compute._MODULE_NAME)) {
    Js.Exn.raiseError(
      `The Compute module(${Compute._MODULE_NAME}) with path(${Internals.Nodejs.Path.resolve2(
          Compute._ABSOLUTE_PATH,
          Compute._MODULE_NAME ++ ".res",
        )}) is not existed.`,
    )
  }
  if !(Internals._MODULE_SUFFIX->Js.String2.startsWith(".")) {
    Js.Exn.raiseError(`the compiled js of Compute module is wrong, eg: .bs.js`)
  }
  await Internals.cleanTempThreadFiles(Compute._ABSOLUTE_PATH, Compute._MODULE_NAME)
  let threadFilePath = await Internals.generateParallelMapThread(
    Compute._ABSOLUTE_PATH,
    Compute._MODULE_NAME,
    ".bs.js",
  )
  await Internals.executeParallelMap(array, parallel, threadFilePath)
}
