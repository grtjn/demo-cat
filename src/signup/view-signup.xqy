xquery version "1.0-ml";

import module namespace signup = "http://marklogic.com/demo-cat/signup" at "/lib/signup.xqy";
import module namespace util = "http://marklogic.com/demo-cat/utilities" at "/lib/utilities.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace jbasic = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "false";

let $id := (xdmp:get-request-field("id"), "test")[1]
let $doc :=
  if ($id) then
    signup:get($id)
  else ()
return
  if ($doc/*) then
    json:transform-to-json($doc)
  else if ($doc) then
    $doc
  else (
    xdmp:set-response-code(500, "Failed"),
    fn:concat("Sign-up ", $id, " not found..")
  )