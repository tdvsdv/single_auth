## Single Authentication (SSO)

#### Plugin for Redmine
[apache]: http://httpd.apache.org/
[ntlm]: http://modntlm.sourceforge.net/
Plugin implements HTTP authentication method in Redmine.

Plugin allows transparent authentication of the User using his domain account throuht Web-server module (for ex. ["Mod_NTLM"][ntlm] in [Apache][apache]).

User authorizes in Web-form on Web-server (for ex. [Apache][apache]). Web-server connects to LDAP-server (for ex. Active Directory) through module (for ex. ["Mod_NTLM"][ntlm]) and checks User`s credentials.
If authorization is complete, module transfers User credentials to Redmine through Environment Variable (for ex. "REMOTE_USER").
Redmine checks User credentials from Variable in it's own Users DB. If User is inside DB, Redmine will login User with it's account, otherwise Redmine will add User into DB, and login User with it's account.

![Scheme](https://github.com/tdvsdv/single_auth/raw/master/screenshots/scheme.png "Scheme")

In Plugin Settings you can set Server environment variable if it differs from "REMOTE_USER".

![Settings](https://github.com/tdvsdv/single_auth/raw/master/screenshots/settings.png "Settings")

#### Installation
Attention! Web-server should be cofigured for plugin with neccessary module and LDAP server.

To install plugin, go to the folder "plugins" in root directory of Redmine.
Clone plugin in that folder.

		git clone https://github.com/tdvsdv/single_auth.git

Restart your web-server.

#### Supported Redmine, Ruby and Rails versions.

Plugin aims to support and is tested under the following Redmine implementations:
* Redmine 2.3.1
* Redmine 2.3.2
* Redmine 2.3.3

Plugin aims to support and is tested under the following Ruby implementations:
* Ruby 1.9.2
* Ruby 1.9.3
* Ruby 2.0.0

Plugin aims to support and is tested under the following Rails implementations:
* Rails 3.2.13

#### Copyright
Copyright (c) 2011-2013 Vladimir Pitin, Danil Kukhlevskiy.

Another plugins of our team you can see on site http://rmplus.pro
