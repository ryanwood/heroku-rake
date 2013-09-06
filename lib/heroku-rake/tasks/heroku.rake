namespace :heroku do
  task :heroku_command_line_client do
    unless heroku_exec('version') =~ /ruby/
      abort "Please install the heroku toolbelt or command line client"
    end
  end

  task :push => :heroku_command_line_client do
    current_branch = `git branch | grep '*' | cut -d ' ' -f 2`.strip
    git_remote     = `git remote -v | grep 'git@heroku.*:#{heroku_app}.git' | grep -e push | cut -f 1 | cut -d : -f 3`.strip

    puts "==> DEPLOYING TO #{current_branch} to master on #{heroku_app}"
    puts "    Use the TO=git_remote option to specify a different environment"

    `git push #{git_remote} #{current_branch}:master`
  end

  task :restart => :heroku_command_line_client do
    puts "==> Restarting #{heroku_app}"
    heroku_exec "restart"
  end

  task :ping => :heroku_command_line_client do
    url = heroku_exec("domains").split("\n").last.strip
    url = "#{heroku_app}.herokuapp.com" if url[/No domain names/]
    `curl http://#{url}#{PING_ENDPOINT}`
  end

  namespace :db do
    task :backup => :heroku_command_line_client do
      puts "==> Capturing backup for #{heroku_app}"
      heroku_exec "pgbackups:capture"
    end

    task :migrate => :heroku_command_line_client do
      puts "==> Migrating #{heroku_app}"
      heroku_exec "run rake db:migrate"
    end
  end

  namespace :maintenance do
    task :on => :heroku_command_line_client do
      puts "==> Maintenance ON for #{heroku_app}"
      heroku_exec "maintenance:on"
    end

    task :off => :heroku_command_line_client do
      puts "==> Maintenance OFF for #{heroku_app}"
      heroku_exec "maintenance:off"
    end
  end

  def heroku_app
    ENV['TO'] ||= DEFAULT_REMOTE
    HEROKU_GIT_REMOTES[ENV['TO'].to_sym]
  end

  def heroku_exec(cmd)
    if defined?(Bundler)
      Bundler.with_clean_env { `heroku #{cmd} --app #{heroku_app}` }
    else
      `heroku #{cmd} --app #{heroku_app}`
    end
  end
end
