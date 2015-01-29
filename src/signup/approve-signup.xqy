xquery version "1.0-ml";

import module namespace signup = "http://marklogic.com/demo-cat/signup" at "/lib/signup.xqy";

declare option xdmp:mapping "false";
declare option xdmp:update "true";

try {
  let $id := (xdmp:get-request-field("id"), "test")[1]

  where signup:approve($id)
  return $id
} catch ($e) {
  xdmp:log($e),
  xdmp:set-response-code(500, "Failed"),
  fn:string($e/error:format-string)
}
