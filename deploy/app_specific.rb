#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the stuff in deploy/lib/server_config.rb
#
class ServerConfig
  
  # apply extra permissions to deployed modules
  alias_method :original_deploy_modules, :deploy_modules
  def deploy_modules()
    original_deploy_modules
    r = execute_query %Q{
      xquery version "1.0-ml";
      
      "Adding exec permissions for demo-cat users to all modules:",
      
      for $uri in cts:uris()
      where fn:not(fn:ends-with($uri, "/"))
      return (
        $uri,
        xdmp:document-set-permissions($uri, (
          xdmp:permission("demo-cat-read-role", "read"),
          xdmp:permission("demo-cat-execute-role", "execute")
        ))
      ),
      
      "",
      "Adding exec permissions for app-user to signup modules:",
      
      for $uri in (cts:uri-match("/signup/*"), cts:uri-match("/lib/*"))
      where fn:not(fn:ends-with($uri, "/"))
      return (
        $uri,
        xdmp:document-add-permissions($uri, (
          xdmp:permission("app-user", "execute")
        ))
      )
    },
    { :db_name => @properties["ml.modules-db"] }
    
    r.body = parse_json(r.body)
    logger.debug r.body
  end

  # fix content permissions
  def fix_permissions()
    r = execute_query %Q{
      xquery version "1.0-ml";
      
      "Adding low-level permissions for demo-cat users to all content:",
      
      for $uri in cts:uris()
      where fn:not(fn:ends-with($uri, "/"))
      return (
        $uri,
        xdmp:document-set-permissions($uri, (
          xdmp:permission("demo-cat-read-role", "read"),
          xdmp:permission("demo-cat-insert-role", "insert"),
          xdmp:permission("demo-cat-update-role", "update")
        ))
      )
    },
    { :db_name => @properties["ml.content-db"] }
    
    r.body = parse_json(r.body)
    logger.info r.body
  end
  
  # apply necessary changes due to data changes
  def migrate()
    r = execute_query %Q{
      xquery version "1.0-ml";
      
      import module namespace sec="http://marklogic.com/xdmp/security" at 
          "/MarkLogic/security.xqy";
      
      for $user-name in collection(sec:users-collection())//sec:user-name/fn:data()
      let $roles := sec:user-get-roles($user-name)
      let $is-admin := ($roles = "admin")
      let $is-demo-cat := ($roles = ("demo-cat-reader-role", "demo-cat-writer-role", "demo-cat-admin-role"))
      where fn:not($user-name = 'admin') and $is-admin and not($is-demo-cat)
      return (fn:concat("Added demo-cat-reader-role to admin user ", $user-name), sec:user-add-roles($user-name, "demo-cat-reader-role"))
    },
    { :db_name => "Security" }
    
    r.body = parse_json(r.body)
    logger.info r.body
  end
  
end
