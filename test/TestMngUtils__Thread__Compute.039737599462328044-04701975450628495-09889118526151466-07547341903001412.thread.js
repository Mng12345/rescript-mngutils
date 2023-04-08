
      const { resolve } = require('path') 
      const Compute = require(resolve('/home/ming/projects/rescript-mngutils/test', 'TestMngUtils__Thread__Compute.bs.js'))
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
                    console.log('error in worker(' + worker.threadId + '), message:\n' + message.message)
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
    