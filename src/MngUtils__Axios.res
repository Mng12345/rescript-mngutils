type t

@module external axios: t = "axios"

module Response = {
  type t<'data> = {data: 'data}
}
@send external _post: (t, ~url: string) => Promise.t<Response.t<'data>> = "post"

@send
external _postWithConfig: (
  t,
  ~url: string,
  ~data: 'data,
  ~config: 'config,
) => Promise.t<Response.t<'result>> = "post"

@send
external _postWithData: (t, ~url: string, ~data: 'data) => Promise.t<Response.t<'result>> = "post"

@send external _get: (t, ~url: string) => Promise.t<Response.t<'data>> = "get"

@send
external _getWithConfig: (t, ~url: string, ~config: 'config) => Promise.t<Response.t<'data>> = "get"

let post = (~url) => {
  axios->_post(~url)
}

let get = (~url) => {
  axios->_get(~url)
}

let getWithConfig = (~url, ~config) => {
  axios->_getWithConfig(~url, ~config)
}

let postWithConfig = (~url, ~data, ~config) => {
  axios->_postWithConfig(~url, ~data, ~config)
}

let postWithData = (~url, ~data) => {
  axios->_postWithData(~url, ~data)
}

@val external encodeURIComponent: string => string = "encodeURIComponent"
