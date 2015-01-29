xquery version "1.0-ml";

module namespace signup = "http://marklogic.com/demo-cat/signup";

import module namespace util = "http://marklogic.com/demo-cat/utilities" at "/lib/utilities.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace jbasic = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "false";

(:
  Make sure to enable sendmail on your Mac to test locally:
  http://www.phase2technology.com/blog/how-to-enable-local-smtp-server-postfix-on-os-x-leopard/
:)

declare function signup:get-host()
{
  let $ref := xdmp:get-request-header("referer")
  return
    if ($ref) then
      fn:tokenize($ref, "/")[3]
    else
      xdmp:host-name(xdmp:host())
};

declare function signup:get(
  $id as xs:string
)
{
  fn:doc(fn:concat('/signups/', $id, '.json'))
};

declare function signup:email-exists(
  $emails as xs:string*,
  $exclude-signup as xs:string?
)
  as xs:boolean
{
  xdmp:exists(
    cts:search(
      xdmp:directory(("/signups/", "/users/"), "infinity"),
      cts:and-query((
        cts:element-query(xs:QName('jbasic:emails'),
          cts:element-value-query(xs:QName('jbasic:item'), $emails)
        ),
        if ($exclude-signup) then
          cts:not-query(
            cts:document-query(fn:concat('/signups/', $exclude-signup, '.json'))
          )
        else ()
      ))
    )
  )
};

declare function signup:login-exists(
  $login as xs:string*,
  $exclude-signup as xs:string?
)
  as xs:boolean
{
  xdmp:exists(
    cts:search(
      xdmp:directory(("/signups/", "/users/"), "infinity"),
      cts:and-query((
        cts:element-value-query(xs:QName('jbasic:name'), $login),
        if ($exclude-signup) then
          cts:not-query(
            cts:document-query(fn:concat('/signups/', $exclude-signup, '.json'))
          )
        else ()
      ))
    )
  )
};

declare function signup:save(
  $profile as document-node()
)
  as xs:boolean
{
  let $has-priv := xdmp:has-privilege("/signups/", "uri") or xdmp:get-current-roles() = xdmp:role("demo-cat-signup-role")
  let $_ := xdmp:log((xdmp:get-current-user(), xdmp:get-current-roles(), $has-priv))
  let $_ :=
    if ($has-priv) then
    
      let $id := fn:string(xdmp:random())
      let $profile :=
        if ($profile/text()) then
          json:transform-from-json($profile)
        else
          $profile
      let $emails := $profile//jbasic:emails/jbasic:item
      
      return
        if (signup:email-exists($emails, ())) then
          fn:error((), "E-mail address already in use")
        else
        
          (: persist profile :)
          let $save :=
            xdmp:document-insert(fn:concat('/signups/', $id, '.json'), $profile, xdmp:default-permissions(), xdmp:default-collections())
            
          (: build message :)
          let $host := signup:get-host()
          let $full-name := "Geert Josten"
          let $message :=
            <div xmlns="http://www.w3.org/1999/xhtml">
              <h2>Confirm sign-up for {$full-name}</h2>
              <div><a href="http://{$host}/sign-up/Confirm/{fn:encode-for-uri($id)}">Confirm</a></div>
            </div>
            
          (: send notification :)
          return
            util:send-notification("Vanguard", "geert.josten@marklogic.com", '[DemoCat] Confirm signup "'||$full-name||'"', $message)
            
    else
      fn:error((),"Not privileged")
  return
    $has-priv
};

declare function signup:confirm(
  $id as xs:string,
  $profile as document-node()
)
  as xs:boolean
{
  let $has-priv := xdmp:has-privilege("/signups/", "uri") or xdmp:get-current-roles() = xdmp:role("demo-cat-signup-role")
  let $_ := xdmp:log((xdmp:get-current-user(), xdmp:get-current-roles(), $has-priv))
  let $_ :=
    if ($has-priv) then
    
      let $profile :=
        if ($profile/text()) then
          json:transform-from-json($profile)
        else
          $profile
      let $login := $profile//jbasic:name
      let $emails := $profile//jbasic:emails/jbasic:item
      
      return
        if (signup:email-exists($emails, $id)) then
          fn:error((), "E-mail address already in use")
        else if (signup:login-exists($login, $id)) then
          fn:error((), "Login name already in use")
        else
        
          (: persist (potentially changed) profile :)
          let $save :=
            xdmp:document-insert(fn:concat('/signups/', $id, '.json'), $profile, xdmp:default-permissions(), xdmp:default-collections())
            
          (: build message :)
          let $host := signup:get-host()
          let $full-name := "Geert Josten"
          let $message :=
            <div xmlns="http://www.w3.org/1999/xhtml">
              <h2>Sign-up request for {$full-name}</h2>
              <div><a href="http://{$host}/sign-up/Review/{fn:encode-for-uri($id)}">Review</a></div>
            </div>
            
          (: send notification :)
          return
            util:send-notification("Vanguard", "geert.josten@marklogic.com", '[DemoCat] Signup request "'||$full-name||'"', $message)
            
    else
      fn:error((),"Not privileged")
  return
    $has-priv
};

declare function signup:approve(
  $id as xs:string
) as xs:boolean {
  let $is-admin := xdmp:get-current-roles() = xdmp:role("admin")
  let $has-priv := xdmp:has-privilege("http://marklogic.com/demo-cat/privilege/signup-approval", "execute")
  let $_ :=
    if (fn:not($is-admin) and $has-priv) then
    
      (: create user :)
      let $login := "test"
      let $full-name := "Geert Josten"
      let $password := fn:string(xdmp:random())
      
      let $exists := try { xdmp:user(fn:concat("demo-cat-", $login)) } catch ($ignore) {}
      return
      
        if ($exists) then
          fn:error((), "Already approved")
        else
      
          let $create :=
            xdmp:eval(fn:concat('
              xquery version "1.0-ml";
          
              import module namespace sec="http://marklogic.com/xdmp/security" at 
                  "/MarkLogic/security.xqy";
          
              sec:create-user(
                "demo-cat-', $login, '",
                "', $full-name, '",
                "', $password, '",
                "demo-cat-reader-role",
                (),
                ()
              )
            '), (), <options xmlns="xdmp:eval"><database>{xdmp:security-database()}</database></options>)
        
            (: build message :)
            let $host := signup:get-host()
          let $message :=
            <div xmlns="http://www.w3.org/1999/xhtml">
              <h2>Sign-up approved for {$full-name}</h2>
              <div><a href="http://{$host}/sign-up/View/{fn:encode-for-uri($id)}">View</a></div>
            </div>
        
          (: send notification :)
          return
            util:send-notification("Vanguard", "geert.josten@marklogic.com", '[DemoCat] Signup approved "'||$full-name||'"', $message)
      
    else
      fn:error((),"Not privileged")
  return
    $has-priv
};

declare function signup:reject(
  $id as xs:string
) as xs:boolean {
  let $is-admin := xdmp:get-current-roles() = xdmp:role("admin")
  let $has-priv := xdmp:has-privilege("http://marklogic.com/demo-cat/privilege/signup-approval", "execute")
  let $_ :=
    if (fn:not($is-admin) and $has-priv) then
    
      (: check user :)
      let $login := "test"
      let $exists := try { xdmp:user(fn:concat("demo-cat-", $login)) } catch ($ignore) {}
      return
    
        if ($exists) then
          fn:error((), "Already approved")
        else
    
          (: build message :)
          let $host := signup:get-host()
          let $full-name := "Geert Josten"
          let $message :=
            <div xmlns="http://www.w3.org/1999/xhtml">
              <h2>Sign-up rejected for {$full-name}</h2>
              <div><a href="http://{$host}/sign-up/View/{fn:encode-for-uri($id)}">View</a></div>
            </div>
      
          (: send notification :)
          return
            util:send-notification("Vanguard", "geert.josten@marklogic.com", '[DemoCat] Signup rejected "'||$full-name||'"', $message)
      
    else
      fn:error((),"Not privileged")
  return
    $has-priv
};
