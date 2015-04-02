# -*- coding: utf-8 -*-
require 'formula'

class VibesPostgresql < Formula
  homepage 'http://www.postgresql.org/'
  url 'http://ftp.postgresql.org/pub/source/v9.2.5/postgresql-9.2.5.tar.bz2'
  sha1 '176ac1de372c06192ec1012b17001414cfa40929'

  option '32-bit'
  option 'no-perl', 'Build without Perl support'
  option 'no-tcl', 'Build without Tcl support'
  option 'enable-dtrace', 'Build with DTrace support'

  depends_on 'openssl'
  depends_on 'readline'
  depends_on 'libxml2' if MacOS.version <= :leopard # Leopard libxml is too old
  depends_on 'ossp-uuid' => :recommended
  depends_on :python => :recommended

  conflicts_with 'postgres-xc',
    :because => 'vibes-postgresql and postgres-xc install the same binaries.'
  conflicts_with 'postgresql',
    :because => 'vibes-postgresql and postgresql install the same binaries.'

  fails_with :clang do
    build 211
    cause 'Miscompilation resulting in segfault on queries'
  end

  # Fix uuid-ossp build issues: http://archives.postgresql.org/pgsql-general/2012-07/msg00654.php
  def patches
    DATA
  end

  def install
    ENV.libxml2 if MacOS.version >= :snow_leopard

    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{share}/#{name}
      --docdir=#{doc}
      --enable-thread-safety
      --with-bonjour
      --with-gssapi
      --with-krb5
      --with-ldap
      --with-openssl
      --with-pam
      --with-libxml
      --with-libxslt
    ]

    args << "--with-ossp-uuid" if build.with? 'ossp-uuid'
    args << "--with-python" if build.with? 'python'
    args << "--with-perl" unless build.include? 'no-perl'
    args << "--with-tcl" unless build.include? 'no-tcl'
    args << "--enable-dtrace" if build.include? 'enable-dtrace'

    if build.with? 'ossp-uuid'
      ENV.append 'CFLAGS', `uuid-config --cflags`.strip
      ENV.append 'LDFLAGS', `uuid-config --ldflags`.strip
      ENV.append 'LIBS', `uuid-config --libs`.strip
    end

    if build.build_32_bit?
      ENV.append 'CFLAGS', "-arch #{MacOS.preferred_arch}"
      ENV.append 'LDFLAGS', "-arch #{MacOS.preferred_arch}"
    end

    system "./configure", *args
    system "make install-world"
  end

  def post_install
    unless File.exist? "#{var}/postgres"
      system "#{bin}/initdb", "#{var}/postgres", '-E', 'utf8'
    end
    inreplace "#{var}/postgres/postgresql.conf", "#max_prepared_transactions = 0", "max_prepared_transactions = 10"
  end

  def caveats
    s = <<-EOS.undent
      initdb #{var}/postgres -E utf8    # create a database
      postgres -D #{var}/postgres       # serve that database
      PGDATA=#{var}/postgres postgres   # …alternatively

      Mac OS X doesn't allow enough shared memory to be allocated by postgres out of the box, so we have to adjust it.

      The following commands will make the increase:

        sudo sysctl kern.sysv.shmall=65536
        sudo sysctl kern.sysv.shmmax=16777216

      You can then create a /etc/sysctl.conf file with the following so this setting will be preserved across restarts

        kern.sysv.shmall=65536
        kern.sysv.shmmax=16777216
    EOS

    s << "\n" << gem_caveats if MacOS.prefer_64_bit?
    return s
  end

  def gem_caveats; <<-EOS.undent
    When installing the postgres gem, including ARCHFLAGS is recommended:
      ARCHFLAGS="-arch x86_64" gem install pg

    To install gems without sudo, see the Homebrew wiki.
    EOS
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres -l #{HOMEBREW_PREFIX}/var/postgres/server.log start"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_prefix}/bin/postgres</string>
        <string>-D</string>
        <string>#{var}/postgres</string>
        <string>-r</string>
        <string>#{var}/postgres/server.log</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/postgres/server.log</string>
    </dict>
    </plist>
    EOS
  end
end


__END__
--- a/src/pl/plpython/Makefile	2011-09-23 08:03:52.000000000 +1000
+++ b/src/pl/plpython/Makefile	2011-10-26 21:43:40.000000000 +1100
@@ -24,8 +24,6 @@
 # Darwin (OS X) has its own ideas about how to do this.
 ifeq ($(PORTNAME), darwin)
 shared_libpython = yes
-override python_libspec = -framework Python
-override python_additional_libs =
 endif
 
 # If we don't have a shared library and the platform doesn't allow it
--- a/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:34:53.000000000 -0700
+++ b/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:35:03.000000000 -0700
@@ -9,6 +9,8 @@
  *-------------------------------------------------------------------------
  */

+#define _XOPEN_SOURCE
+
 #include "postgres.h"
 #include "fmgr.h"
 #include "utils/builtins.h"
