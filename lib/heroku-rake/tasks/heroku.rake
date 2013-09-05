namespace :heroku do
  task :heroku_command_line_client do
    unless `heroku version` =~ /ruby/
      abort "Please install the heroku toolbelt or command line client"
    end
  end

  task :push => :heroku_command_line_client do
    current_branch = `git branch | grep '*' | cut -d ' ' -f 2`.strip
    git_remote     = `git remote -v | grep 'git@heroku.*:#{heroku_app}.git' | grep -e push | cut -f 1 | cut -d : -f 3`.strip

    puts "***** DEPLOYING TO #{heroku_app} *****"
    puts "***** use the TO=git_remote option to specify a different environment *****"

    sh "git push #{git_remote} #{current_branch}:master"
  end

  task :restart => :heroku_command_line_client do
    sh "heroku restart --app #{heroku_app}"
  end

  task :ping => :heroku_command_line_client do
    url = `heroku domains --app #{heroku_app}`.split("\n").last.strip
    url = "#{heroku_app}.herokuapp.com" if url[/No domain names/]
    sh "curl http://#{url}#{PING_ENDPOINT}"
  end

  namespace :db do
    task :backup => :heroku_command_line_client do
      sh "heroku pgbackups:capture --app #{heroku_app}"
    end

    task :migrate => :heroku_command_line_client do
      puts "***** MIGRATING #{heroku_app} *****"
      sh "heroku run rake db:migrate --app #{heroku_app}"
    end
  end

  namespace :maintenance do
    task :on => :heroku_command_line_client do
      sh "heroku maintenance:on --app #{heroku_app}"
    end

    task :off => :heroku_command_line_client do
      sh "heroku maintenance:off --app #{heroku_app}"
    end
  end

  def heroku_app
    ENV['TO'] ||= DEFAULT_REMOTE
    HEROKU_GIT_REMOTES[ENV['TO'].to_sym]
  end
end
