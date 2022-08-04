type t<'value> = {
  parallel: int,
  tasks: array<(int, unit => Promise.t<'value>)>,
  results: array<option<Belt.Result.t<'value, exn>>>,
}

let make = (tasks, parallel) => {
  {
    parallel: parallel,
    tasks: tasks->Belt.Array.mapWithIndex((index, task) => (index, task)),
    results: tasks->Belt.Array.map(_ => None),
  }
}

exception Error(string)

let execute = task => {
  task()
  ->Promise.then(result => {
    Promise.resolve(Belt.Result.Ok(result))
  })
  ->Promise.catch(exn => {
    Promise.resolve(Belt.Result.Error(exn))
  })
}

let executeTimeout = (task, timeout) => {
  Promise.make((resolve, _) => {
    let timeoutId = ref(None)
    let alreadyTimeout = ref(false)
    let alreadyResolved = ref(false)
    // execute the task
    task()
    ->Promise.then(result => {
      if alreadyTimeout.contents {
        ignore()
      } else {
        switch timeoutId.contents {
        | None => ignore()
        | Some(timerId) => Js.Global.clearTimeout(timerId)->ignore
        }
        alreadyResolved := true
        resolve(. Belt.Result.Ok(result))
      }
      Promise.resolve()
    })
    ->Promise.catch(exn => {
      if alreadyTimeout.contents {
        ignore()
      } else {
        switch timeoutId.contents {
        | None => ignore()
        | Some(timeoutId) => Js.Global.clearTimeout(timeoutId)->ignore
        }
        alreadyResolved := true
        resolve(. Belt.Result.Error(exn))
      }
      Promise.resolve()
    })
    ->ignore
    // execute the timer
    timeoutId := Js.Global.setTimeout(() => {
        alreadyTimeout := true
        if alreadyResolved.contents {
          ignore()
        } else {
          resolve(. Belt.Result.Error(Error("time out.")))
        }
      }, timeout)->Some
  })
}

let runWithPollTimeWithTimeout = (runner, pollTime, timeout) => {
  if runner.tasks->Belt.Array.length < runner.parallel {
    Promise.resolve(MngUtils__Result.Err(Error("the count of tasks must bigger than parallel.")))
  } else {
    Promise.make((resolve, _) => {
      let rec wait = () => {
        if (
          runner.results->Belt.Array.some(item =>
            switch item {
            | Some(_) => false
            | None => true
            }
          )
        ) {
          Js.Global.setTimeout(() => {
            wait()
          }, pollTime)->ignore
        } else {
          resolve(.
            MngUtils__Result.Ok(
              runner.results->Belt.Array.map(result => result->Belt.Option.getUnsafe),
            ),
          )
        }
      }
      // execute tasks
      let slot = ref([])
      for _ in 0 to runner.parallel - 1 {
        slot.contents->Js.Array2.push(None)->ignore
      }
      let tasks = runner.tasks->Js.Array2.concat([])
      let rec runWithParallel = () => {
        if tasks->Belt.Array.length === 0 {
          // wait the slot executed done
          Js.Global.setTimeout(() => {
            Promise.all(
              slot.contents->Belt.Array.keepMap(task => task->Belt.Option.map(task => task)),
            )
            ->Promise.then(result => {
              result->Belt.Array.forEach(item => {
                let (result, slotIndex, taskIndex) = item
                // update results
                runner.results[taskIndex] = Some(result)
                // update slot
                slot.contents[slotIndex] = None
              })
              Promise.resolve()
            })
            ->ignore
          }, 0)->ignore
        } else {
          // check if the slot has empty position
          slot :=
            slot.contents->Belt.Array.mapWithIndex((index, task) => {
              switch task {
              | None => {
                  // get a task from tasks
                  let task = tasks->Js.Array.shift
                  task->Belt.Option.map(((taskIndex, task)) => {
                    switch timeout {
                    | Some(timeout) =>
                      executeTimeout(task, timeout)->Promise.then(result => {
                        Promise.resolve((result, index, taskIndex))
                      })
                    | None =>
                      execute(task)->Promise.then(result => {
                        Promise.resolve((result, index, taskIndex))
                      })
                    }
                  })
                }
              | Some(task) => Some(task)
              }
            })
          let hasTask = slot.contents->Belt.Array.some(task => {
            switch task {
            | None => false
            | Some(_) => true
            }
          })
          if hasTask {
            Promise.race(
              slot.contents->Belt.Array.keepMap(task => task->Belt.Option.map(task => task)),
            )
            ->Promise.then(result => {
              let (result, slotIndex, taskIndex) = result
              // update results
              runner.results[taskIndex] = Some(result)
              // update slot
              slot.contents[slotIndex] = None
              // into next loop
              Js.Global.setTimeout(() => {
                runWithParallel()
              }, 0)->ignore
              Promise.resolve()
            })
            ->ignore
          } else {
            // every task is done.
            ignore()
          }
        }
      }
      runWithParallel()
      wait()
    })
  }
}

let run = runner => {
  runner->runWithPollTimeWithTimeout(50, None)
}

let runWithTimeout = (runner, timeout) => {
  runner->runWithPollTimeWithTimeout(50, Some(timeout))
}
