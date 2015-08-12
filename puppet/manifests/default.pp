# Red Hat Vagrant Tech Talk Base Puppet Manifest

$project_name = "tech-talk"

    include packageUpdate
    include baseInstall
    include gnomeInstall
    include afterInstall
    include ssh
    include git

class packageUpdate 
{
   exec
   {
      "dnf update packages":
      path => ["/usr/bin/","/usr/sbin/","/bin"],
      command => "dnf -y upgrade",
      timeout => 1800,
      user => root
   }
}

class baseInstall
{
	$packages = ['kernel-debug', 'gcc', 'kernel-devel']
	package{
		$packages:
		ensure => latest
	}

	#Example file sync
	file {
   		'/home/vagrant/.bashrc':
      		owner => 'vagrant',
      		group => 'vagrant',
      		mode  => '0644',
      		source => '/vagrant/puppet/files/.bashrc';
  	}
}

class gnomeInstall
{
   exec { "GUI Group Install":
      path => ["/usr/bin/","/usr/sbin/","/bin"],
      command => 'dnf -y group install "Fedora Workstation"',
      timeout => 1800,
      user => root
   }
   package 
   {   "gdm":
       ensure => latest
   }
}

class afterInstall
{
   exec { "enable gui":
      path => ["/usr/bin/","/usr/sbin/","/bin"],
      command => 'systemctl set-default graphical.target',
      timeout => 1800,
      user => root
  }
}

class ssh
{
    service { "sshd":        
        ensure    => "running",
        enable    => "true"
    }
    file {
        '/etc/gdm/custom.conf':
            owner => 'root',
            group => 'root',
            mode  => '0644',
            source => '/vagrant/puppet/files/custom.conf';
  	}

    exec { 
        'install jboss eap':
            path      => '/usr/bin:/usr/sbin:/bin',
            command   => 'unzip -o /vagrant/puppet/binaries/jboss-eap-6.4.0.zip -d /opt && chown -R vagrant:vagrant /opt/jboss*',
            timeout   => 1800,
            user      => root,
    }

    exec { 
        'install jboss devstudio':
            path      => '/usr/bin:/usr/sbin:/bin',
            command   => 'java -jar /vagrant/puppet/binaries/jboss-devstudio-8.1.0.GA-installer-standalone.jar /vagrant/puppet/files/InstallConfigRecord.xml',
            timeout   => 1800,
            user      => vagrant
    }
}

class  
{ 'java':
  distribution => 'jdk',
}

git::config { 'user.name':
  value => 'Vagrant User',
}

git::config { 'user.email':
  value => 'vagrant@example.com',
}


# Install Maven
class { "maven::maven":
  version => "3.2.5", # version to install
  # you can get Maven tarball from a Maven repository instead than from Apache servers, optionally with a user/password
  repo => {
    #url => "http://repo.maven.apache.org/maven2",
    #username => "",
    #password => "",
  }
} ->

# Setup a .mavenrc file for the specified user
maven::environment { 'maven-env' : 
    user => 'vagrant',
    # anything to add to MAVEN_OPTS in ~/.mavenrc
    maven_opts => '-Xmx1384m',       # anything to add to MAVEN_OPTS in ~/.mavenrc
    maven_path_additions => "",      # anything to add to the PATH in ~/.mavenrc
} ->
 
# Create a settings.xml with the repo credentials
maven::settings { 'maven':
    user => 'vagrant',
    repos => [
        {
              id        => "repository.apache.org-releases",
              url       => "https://repository.apache.org/content/groups/public",
              name      => "Apache Release Repository",
              snapshots => {  enabled => 'false', }
        }, {
              id        => "repository.apache.org-staging",
              name      => "Apache Release Repository",
              url       => "https://repository.apache.org/content/groups/staging",
              snapshots => {  enabled => 'false', }
        }, {
              id        => "apache-incubating-repository",
              name      => "Apache Incubating Repository",
              url       => "http://people.apache.org/repo/m2-incubating-repository",
              snapshots => {  enabled => 'false', }
        }, {
              id        => "repository.jboss.org-product-all",
              name      => "JBoss Products Release All",
              url       => "https://repository.jboss.org/nexus/content/groups/product-all",
              snapshots => {  enabled => 'false', }
        },

        #SNAPSHOT REPOS
         {
              id        => "repository.apache.org-snapshots",
              name      => "Apache Snapshot Repository",
              url       => "https://repository.apache.org/content/groups/snapshots",
              snapshots => {  enabled => 'true', }
        }       
    ],
    properties => {
        'project.build.sourceEncoding' => 'UTF-8',
        'maven.compiler.source' => '1.7',
        'maven.compiler.target' => '1.7',
        'maven.compiler.fork'   => 'true',
        'maven.compiler.maxmem' => '256m',
        'maven.compiler.verbose' => 'true',
        'maven.test.skip'       => 'false',
        'maven.test.failure.ignore' => 'false',
        'maven.test.redirectTestOutputToFile' => 'false',
    }
}




