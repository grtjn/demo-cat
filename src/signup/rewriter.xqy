xquery version "1.0-ml";

let $url := xdmp:get-request-url()
let $new-url :=
  if (fn:contains($url, "?")) then
    fn:concat("/signup", fn:replace($url, "\?", ".xqy?"))
  else
    fn:concat("/signup", $url, ".xqy")
let $_ := xdmp:log($new-url)
return $new-url