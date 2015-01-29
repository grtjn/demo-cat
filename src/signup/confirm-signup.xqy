xquery version "1.0-ml";

import module namespace signup = "http://marklogic.com/demo-cat/signup" at "/lib/signup.xqy";

declare option xdmp:mapping "false";
declare option xdmp:update "true";

try {
  let $id := (xdmp:get-request-field("id"), "test", xdmp:random())[1]
  let $profile := (xdmp:get-request-body("text"), document{ '{ test: "test" }' })[1]

  where signup:confirm($id, $profile)
  return
    $id
} catch ($e) {
  xdmp:log($e),
  xdmp:set-response-code(500, "Failed"),
  fn:string($e/error:format-string)
}
