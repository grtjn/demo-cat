(function () {
  'use strict';

  angular.module('demoCat')
    .controller('SignupCtrl', ['$scope', 'MLRest', 'User', '$location', '$http', '$routeParams', function ($scope, mlRest, user, $location, $http, $routeParams) {
      var action = $routeParams.action;
      var id = $routeParams.id;
      var model = {
        user: user, // GJo: a bit blunt way to insert the User service, but seems to work
        signup: { role: 'viewer' },
        newEmail: undefined,
        action: action,
        id: id
      };
      
      user.signup = true;

      if (id && action !== 'Request') {
        $http
        .get(
          '/signup/view-signup?id='+encodeURIComponent(id)
        )
        .then(
          function(response) {
            model.signup = response.data;
            model.signup.name = model.signup.name ? model.signup.name.replace(/^demo-cat-/, '') : '';
            model.newEmail = model.signup.emails[0];
          },
          function(error) {
            model.signupFailed = error.data;
          }
        );
      }
      
      angular.extend($scope, {
        model: model,
        // addEmail: function() {
        //   if ($scope.profileForm.newEmail.$error.email) {
        //     return;
        //   }
        //   if (!$scope.model.user.emails) {
        //     $scope.model.user.emails = [];
        //   }
        //   $scope.model.user.emails.push(model.newEmail);
        //   model.newEmail = '';
        // },
        // removeEmail: function(index) {
        //   $scope.model.user.emails.splice(index, 1);
        // },
        submit: function(choice) {
          model.signupRequested = false;
          model.signupFailed = '';
          var ok = true;
          if (!model.signup.name) {
            model.signupFailed = model.signupFailed + 'User login is required<br/>';
            ok = false;
          }
          if (!model.signup.fullname) {
            model.signupFailed = model.signupFailed + 'User full name is required<br/>';
            ok = false;
          }
          if (!model.newEmail) {
            model.signupFailed = model.signupFailed + 'E-mail is required<br/>';
            ok = false;
          }
          if (model.user.password !== model.user.password2) {
            model.signupFailed = model.signupFailed + 'Passwords don\'t match<br/>';
            ok = false;
          }
          if (!model.signup.role) {
            model.signupFailed = model.signupFailed + 'User role is required<br/>';
            ok = false;
          }
          if (ok) {
            if (choice) {
              action = choice;
            }
            if (!id) {
              id = model.newEmail;
            }
            $http
            .post(
              '/signup/' + action.toLowerCase() + '-signup?id='+encodeURIComponent(id), {
                name: model.signup.name ? 'demo-cat-' + model.signup.name : '',
                fullname: model.signup.fullname,
                emails: [model.newEmail]
              }
            )
            .then(
              function() {
                model.signupRequested= true;
              },
              function(error) {
                model.signupFailed = error.data.replace(/\s*\(err:.*$/, '');
              }
            );
          }
        }
      });
    }]);
}());
