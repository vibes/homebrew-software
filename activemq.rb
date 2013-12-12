require 'formula'

class Activemq < Formula
  url 'http://www.apache.org/dyn/closer.cgi?path=activemq/apache-activemq/5.5.1/apache-activemq-5.5.1-bin.tar.gz'
  homepage 'http://activemq.apache.org/'
  md5 '3e10c163c5e3869a9720d47849a5ae29'

  skip_clean 'libexec/webapps/admin/WEB-INF/jsp'

  def startup_script name
    <<-EOS.undent
      #!/bin/bash
      export ACTIVEMQ_HOME=#{libexec}
      export ACTIVEMQ_BASE=#{var}/activemq
      export JAVA_CMD=$(which java)
      exec #{libexec}/bin/#{name} $@
    EOS
  end

  # turn on DLQ per queue and stomp+nio connector
  # fix a bug in the bin/activemq script
  def patches
    DATA
  end

  def install
    rm_rf Dir['bin/linux-x86-*']

    prefix.install %w{ LICENSE NOTICE README.txt }
    libexec.install Dir['*']

    (sbin+'activemq').write startup_script('activemq')
    (sbin+'activemq-admin').write startup_script('activemq-admin')

    (prefix+'org.apache.activemq-server.plist').write startup_plist
    (prefix+'org.apache.activemq-server.plist').chmod 0644

    conf_file = (var+'activemq/conf')
    if conf_file.exist?
      ohai "Using your existing config in directory: #{conf_file}"
    else
      ohai "Installing default config files to #{conf_file}"
      (var+'activemq/conf').install Dir[libexec+'conf/*']
    end
  end

  def caveats
    <<-EOS.undent
    If this is your first install, automatically load on login with:
        mkdir -p ~/Library/LaunchAgents
        cp #{prefix}/org.apache.activemq-server.plist ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/org.apache.activemq-server.plist

    If this is an upgrade and you already have the org.apache.activemq-server.plist loaded:
        launchctl unload -w ~/Library/LaunchAgents/org.apache.activemq-server.plist
        cp #{prefix}/org.apache.activemq-server.plist ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/org.apache.activemq-server.plist

    If you didn't have one already, we installed the default activemq.xml to #{var}/activemq/conf/activemq.xml

      To start activemq manually:
        activemq console
    EOS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.apache.activemq-server</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/sbin/activemq</string>
      <string>console</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
    <key>StandardErrorPath</key>
    <string>/Users/#{`whoami`.chomp}/Library/Logs/ActiveMQ/err.log</string>
    <key>StandardOutPath</key>
    <string>/Users/#{`whoami`.chomp}/Library/Logs/ActiveMQ/out.log</string>
  </dict>
</plist>
    EOPLIST
  end

end
__END__
diff --git a/bin/activemq b/bin/activemq
index c159d11..eb7b2f1 100755
--- a/bin/activemq
+++ b/bin/activemq
@@ -249,7 +249,7 @@ case "`uname`" in
   CYGWIN*) OSTYPE="cygwin" ;;
   Darwin*) 
            OSTYPE="darwin"
-           if [-z "$JAVA_HOME"] && [ "$JAVACMD" = "auto" ];then
+           if [ -z "$JAVA_HOME" ] && [ "$JAVACMD" = "auto" ];then
              JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home
            fi
            ;;
diff --git a/conf/activemq.xml b/conf/activemq.xml
index 73051fa..5b9c5df 100644
--- a/conf/activemq.xml
+++ b/conf/activemq.xml
@@ -54,6 +54,9 @@
                   </pendingSubscriberPolicy>
                 </policyEntry>
                 <policyEntry queue=">" producerFlowControl="true" memoryLimit="1mb">
+                  <deadLetterStrategy>
+                      <individualDeadLetterStrategy queuePrefix="DLQ." />
+                  </deadLetterStrategy>
                   <!-- Use VM cursor for better latency
                        For more information, see:
                        
@@ -121,6 +124,7 @@
         -->
         <transportConnectors>
             <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
+            <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:61613?transport.closeAsync=false"/>
         </transportConnectors>
 
     </broker>

