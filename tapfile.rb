autoload(:Digest, 'digest/md5')

# External::Rubyspec::Checkout::manifest checkout or update rubyspecs
# 
# Checks out the rubyspecs for arrays into the 'test/rubyspec'
# directory.  The rubyspecs are copied over in this format:
#
#   # <checksum>
#   # Generated: <date>
#   ##########################...
#   # <escaped source content>
#   <source content>
#
# The format tracks the original source for rubyspec and allows 
# revisions within the content to test duck typed behavior. Subsequent
# calls to checkout will update any out-of-date rubyspecs.
#
# Checkout requires that git be installed (on windows, this also 
# means that git must be run from the git bash shell).
#
module External
  module Rubyspec
    class Checkout < Tap::FileTask
      
      # 'Copies' (see above for the copy format) the source to the 
      # target if the target doesn't exist or is out of date.  
      # Out-of-dateness is established by checking the checksum of 
      # the source with the checksum printed on the first line of 
      # an existing target.
      #
      def copy_spec(source, target)
        content = File.read(source)
        checksum = Digest::MD5.hexdigest(content)

        # check the existing file -- if the checksum is equal, move on
        unless File.exists?(target) && File.read(target)[2, 32] == checksum
          log_basename :copy, source
          prepare(target)
          File.open(target, "wb") do |file|
            file.puts "# #{checksum}"
            file.puts "# Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            file.puts "#" * 80
            file.puts "# #{content.split(/\r?\n/).join("\n# ")}"
            file.puts
            file.puts "puts 'not implemented: #{File.basename(source)}'"
            file.puts "unless true"
            file.puts content.strip
            file.puts "end # remove with unless true"
          end
        end
      end
      
      def process
        if File.exists?(app[:rubyspec])
          app.chdir(:rubyspec) { sh "git pull" }
        else
          sh "git clone git://github.com/rubyspec/rubyspec.git"
        end
        
        # copy the 1.8 array specs
        app.glob(:rubyspec, '1.8/core/array/**/*.rb').each do |spec|
          copy_spec(spec, app.translate(spec, :rubyspec, 'test/rubyspec'))
        end
        
        # copy the 1.9 array specs
        app.glob(:rubyspec, '1.9/core/array/**/*.rb').each do |spec|
          copy_spec(spec, app.translate(spec, :rubyspec, 'test/rubyspec'))
        end
        
        # copy the helpers
        app.glob(:rubyspec, '**/spec_helper.rb').each do |spec|
          copy_spec(spec, app.translate(spec, :rubyspec, 'test/rubyspec'))
        end
      end
      
    end
  end
end