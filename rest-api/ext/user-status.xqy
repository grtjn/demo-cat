xquery version "1.0-ml";

module namespace user = "http://marklogic.com/rest-api/resource/user-status";

declare namespace roxy = "http://marklogic.com/roxy";

(:
 :)
declare function user:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  map:put($context, "output-types", "application/json"),
  xdmp:set-response-code(200, "OK"),
  let $current := xdmp:get-current-user()
  let $profile := fn:doc("/users/" || $current || ".json")
  return
    document {
      xdmp:to-json(
        map:new((
          map:entry("authenticated", fn:true()),
          map:entry("username", $current),
          map:entry("profile", map:new((
            map:entry("fullname", $profile//*:fullname/data(.)),
            map:entry("emails", json:to-array($profile//*:emails/*:item/data(.)))
          ))),
          map:entry("roles", json:to-array(xdmp:get-current-roles()))
        ))
      )
    }
};
