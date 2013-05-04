require 'zip/zipfilesystem'
require 'json'

class Contest
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :title,           type: String
  field :description,     type: String
  field :path,            type: String
  field :time_start,      type: DateTime
  field :duration,        type: Integer, :default => 300#minutes
  field :type,            type: Integer, :default => 0  #"ACM", "IOI"
  field :problems_count,  type: Integer, :default => 0  #problems[0] <- it is template for other problem
  field :confirm_participants,  type: Boolean, :default => false
  field :last_success_submit, type: String

  belongs_to :user
  has_many :problems
  has_many :participants

  after_create :set_path, :create_folder, :create_template_problem
  before_destroy :clear  
  
  def set_path
    self.path = (Contest.exists?) ? 
      ( Contest.all.sort_by{|i| i.path.to_i}.last.path.to_i + 1 ).to_s : '1'
  end

  def create_folder
    FileUtils.mkdir_p self.contest_dir
  end

  def create_template_problem
    self.problems_create(0)
  end

  def clear
    #destroy all problems and submits
    self.problems.destroy_all
    #destroy all participants
    self.participants.destroy_all
    #delete contest folder
    FileUtils.rm_rf self.contest_dir
  end


  def contest_dir
    "#{Rails.root}/judge-files/contests/#{self.path}"
  end

  def started?
    (!self.time_start.nil? && Time.now > self.time_start) ? true : false
  end

  def over?
    (self.started? && Time.now > self.time_start+self.duration.minutes) ? true : false
  end

  def start(params, now = false)
    self.time_start = (now==true) ? DateTime.now : Contest.new(params).time_start
    self.duration = Contest.new(params).duration
  end

  def stop
    self.duration = ((DateTime.now - self.time_start)*24*60).to_i
  end

  def restart(params)
    #delete
    self.participants.destroy_all
    #restart
    self.start(params, true)
  end

  def continue(params)
    time_now      = DateTime.now
    new_duration  = Contest.new(params).duration.minutes
    
    self.time_start = self.time_start - self.time_start.sec.seconds + time_now.sec.seconds
    self.duration = (((time_now + new_duration) - self.time_start)*24*60).to_i
  end

  def time_left
    #return in seconds
    return (!self.started? || self.over?) ? 0 : (((self.time_start + self.duration.minutes) - DateTime.now)*24*60*60).to_i
  end

  def upd_problems_count(number)
    if self.problems_count > number
      self.problems_destroy(number+1, self.problems_count)

    elsif self.problems_count < number
      self.problems_create(self.problems_count+1, number)

    end
  end

  def problems_create(from, to=nil)
    to = from if to.nil?
    for i in from..to do
      problem = Problem.new({
        :contest => self,
        :order => i
      });
      #set template problems data
      problem.use_template if not problem.order == 0
      problem.save
      self.problems << problem

    end
    self.problems_count = self.problems.size - 1
    self.save

    self.participants.each do |participant|
      b = Array.new(self.problems_count-participant.a.size+1, 0)
      participant.a = participant.a + b
      participant.penalties = participant.penalties + b
      participant.save
    end
  end

  def problems_destroy(from, to=nil)
    to = from if to.nil?

    for i in from..to do
      #destory array's cell and object
      problem = self.problems.find_by(order: i)
      problem.destroy
      self.problems.delete(problem)
    end
    self.problems_count = self.problems.size - 1
    self.save

    self.participants.each do |participant|
      participant.a = participant.a[0..self.problems_count]
      participant.penalties = participant.penalties[0..self.problems_count]
      participant.save
    end
  end

  def put_problems(archive)
    ret_status    = {:notice => [], :error => []}
    exts_archive  = ['.zip', '.tgz']
    exts_code     = ['.pas', '.dpr', '.cpp']
    exts_doc      = ['.pdf', '.doc', '.docx']
    archive_ext  = File.extname(archive.original_filename)

    if not exts_archive.include? archive_ext
      ret_status[:error] << 'archive not supported'
      ret_status[:error] << "upload only #{exts_archive.join(', ')} archives"
      return ret_status
    end
    #clear & write archive_file(.zip) in tests_dir
    self.clear
    self.create_template_problem
    tmp_dir = self.contest_dir+'/tmp'
    FileUtils.mkdir_p tmp_dir
    File.open(Rails.root.join(tmp_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files from file
    if archive_ext == '.zip'
      Zip::ZipFile.open(tmp_dir+"/#{archive.original_filename}"){ |zip_file|
        zip_file.each { |f|
          f_path=File.join(tmp_dir, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        }
      }
    elsif archive_ext == '.tgz'
      pid, stdin, stdout, stderr = Open4::popen4 "tar zxvf \'#{tmp_dir+'/'+archive.original_filename}\' -C \'#{tmp_dir}\'"
      ignored, status = Process::waitpid2 pid
    end
    #remove(delete) archive file
    File.delete File.join(tmp_dir, archive.original_filename)

    #separate 'problems files' from other files
    files = Dir.entries(tmp_dir).sort[2..-1]
    problems_files = [{}]
    files.each do |t|
      next if not t.include? "_"
      if t[0..8].downcase == "template_"
        m = [t[0..8]]
        k = 0
      elsif (/[0-9]+_/ =~ t) == 0
        m = /[0-9]+_/.match t
        k = m[0][0..-2].to_i
      elsif (/([a-z]|[A-Z])_+/ =~ t) == 0
        m = /([a-z]|[A-Z])_+/.match t
        k = 1 + m[0][0..-2].ord - ((m[0][0..-2].downcase == m[0][0..-2]) ? 'a'.ord : 'A'.ord)
      else
        next
      end
      problems_files[k] = {} if problems_files[k].nil?
      ext = File.extname(t)

      if t[ m[0].size ].downcase=='c' && exts_code.include?(ext) then
        #checker:   a_[c]..[.cpp]
        problems_files[k].merge!(:checker => t)

      elsif exts_doc.include? ext
        #statement: a_..[.pdf]
        problems_files[k].merge!(:statement => t)

      elsif t[ m[0].size ].downcase=='s' && exts_code.include?(ext) then
        next if k == 0 #skip for Template
        #solution:  a_[s]..[.cpp]
        problems_files[k].merge!(:solution => t)

      elsif exts_archive.include? ext
        next if k == 0 #skip for Template
        #tests:     a_..[.zip]
        problems_files[k].merge!(:tests => t)

      end
    end
    files = files - problems_files.map(&:values).flatten

    #put problems with order
    #create problems
    problems_files.each_with_index do |h, i|
      next if i == 0
      self.upd_problems_count(i)
    end
    ret_status[:notice] << "#{self.problems_count} problems created"

    #put problem's settings (and template's settings)
    files.each do |t|
      ext = File.extname(t)
      
      if exts_doc.include? ext
        ##put Contest's statement
        template  = self.problems.find_by(order: 0)
        file = ActionDispatch::Http::UploadedFile.new({
            :filename => t, 
            :tempfile => File.new(tmp_dir+'/'+ t)})
        template.put_statement(file)
        template.save
        ret_status[:notice] << 'Contest\'s Statement OK'
        next
      end

      if ext == '.json'
        ##put problem's settings
        ###parse json to hash 'set'
        begin
          set = JSON.parse(IO.read(tmp_dir+'/'+t))
        rescue JSON::ParserError => e
          ret_status[:error] << 'JSON Parsing error:'
          ret_status[:error] << e.message
          set = nil
        end
        next if set.nil?
        ###set the settings
        ####Template must be first
        template_sets = set.delete("template")
        template_sets = set.delete("0") if template_sets.nil?
        set = set.sort {|a1, a2| a1[0] <=> a2[0]}
        set.unshift(["template", template_sets]) if not template_sets.nil?

        set.each do |problem_name, sets|
          #find problem
          if problem_name.downcase == 'template'
            k = 0
          elsif (/^-?(\d+(\.\d+)?|\.\d+)$/ =~ problem_name) == 0 #only digits
            k = problem_name.to_i
          elsif (/([a-z]|[A-Z])/ =~ problem_name) == 0 && problem_name.size == 1 then #only letter
            k = 1 + problem_name.ord - ((problem_name.downcase == problem_name) ? 'a'.ord : 'A'.ord)
          else
            ret_status[:error] << "JSON: Problem \"#{problem_name}\" not identified"
            next
          end
          problem = self.problems.where(order: k)
          if problem.count == 0
            ret_status[:error] << "JSON: Problem \'#{problem_name}\' as ##{k} not found"
            next
          end
          problem = problem[0]

          #setup settings
          report_header = (problem.order == 0) ? "Template: " : "Problem #{problem.order}: "

          if not sets.class == Hash
            ret_status[:error] << report_header + 'there is no hash with settings'
            next
          end
          #setup time_limit and memory_limit
          sets.each do |key, value|
            key = key.downcase
            if key == 'tl' || key == 'ml'
              value = value.to_i
              if value > 0
                if key == 'tl'
                  problem.time_limit   = value
                else
                  problem.memory_limit = value
                end

                ret_status[:notice] << report_header + "#{key.upcase}=#{value}"

              else
                ret_status[:error] << report_header + "#{key.upcase}=#{value} is incorrect"

              end
            elsif key == 'in' || key == 'out'
              #just skip

            else
              ret_status[:error] << report_header + "\'#{key}\' not identified"

            end
          end
          #setup input_file and output_file
          begin
            input  = sets['in']
            output = sets['out']
            input_ext  = (input.nil?)  ? '' : File.extname(input)
            output_ext = (output.nil?) ? '' : File.extname(output)
            ##set input file with output.nil?
            if input.nil? || input.size == 0 then# '' -> nil (as standart input)              
              problem.input_file  = nil
              problem.output_file = nil if output.nil?

            elsif input.size > 0 && input_ext.size == 0 # 'sort' -> 'sort.in'
              problem.input_file  = input+'.in'
              problem.output_file = input+'.out' if output.nil?

            elsif input_ext == '.in' # 'sort.in' -> 'sort.in'
              problem.input_file  = input
              problem.output_file = input[0..-4]+'.out' if output.nil?

            else
              problem.input_file  = input
              problem.output_file = nil if output.nil?
              ret_status[:error] << report_header + 'output_file not declared'

            end

            ##set output file
            if output.nil?
              #nothing

            elsif output.size == 0 # '' -> nil (as standart output)
              problem.output_file  = nil

            elsif output.size > 0 && output_ext.size == 0 # 'sort' -> 'sort.out'
              problem.output_file  = output+'.out'

            else # 'sort.out' -> 'sort.out'
              problem.output_file  = output

            end
            ret_status[:notice] << report_header + "input_file=\'#{(problem.input_file.nil?) ? 'standart_input' : problem.input_file}\', output_file=\'#{(problem.output_file.nil?) ? 'standart_output' : problem.output_file}\'"
          end

          problem.save
          self.upd_problems_template if problem.order == 0
        end
      end
    end


    #put problem's files
    problems_files.each_with_index do |h, i|
      problem = self.problems.find_by(order: i)
      report_header = (problem.order==0) ? "Template: " : "Problem #{i}: "
      ##put tests
      if problem.order == 0
        #just skip, template doesn't have tests
      elsif h[:tests].nil?
        ret_status[:error] << report_header + "there is no Tests"
        next
      else
        tests_archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "#{h[:tests]}",
          :tempfile => File.new("#{tmp_dir}/#{h[:tests]}")
        })
        tests_status = problem.put_tests( tests_archive )
        if tests_status[:status] == 'OK'
          ret_status[:notice] << report_header + 'Tests OK'
        else
          ret_status[:error] << report_header << '-' + tests_status[0]
        end
      end
      ##put checker
      if not h[:checker].nil?
        checker = ActionDispatch::Http::UploadedFile.new({
          :filename => "#{h[:checker]}",
          :tempfile => File.new("#{tmp_dir}/#{h[:checker]}")
        })
        checker_status = problem.put_checker(checker)
        if checker_status[:status] == 'OK'
          ret_status[:notice] << report_header + 'Checker OK'

        else
          ret_status[:error]  << report_header + 'Checker got ' + checker_status[:status]
          checker_status[:error].each {|x| ret_status[:error] << '-' + x } if not checker_status[:error].nil?

        end
      end
      ##put statement
      if not h[:statement].nil?
        statement = ActionDispatch::Http::UploadedFile.new({
          :filename => "#{h[:statement]}",
          :tempfile => File.new("#{tmp_dir}/#{h[:statement]}")
        })
        problem.put_statement( statement )
        ret_status[:notice] << report_header + 'Statement OK'
      end
      ##put solution
      if problem.order == 0
        #just skip, template doesn't have solution
      elsif not h[:solution].nil?
        sfile = ActionDispatch::Http::UploadedFile.new({
          :filename => "#{h[:solution]}",
          :tempfile => File.new("#{tmp_dir}/#{h[:solution]}")
        })
        problem.save
        solution_status = problem.put_solution( sfile )
        if solution_status[:status] == 'OK'
          ret_status[:notice] << report_header + 'Solution OK'
        else
          ret_status[:error]  << report_header + "Solution got #{solution_status[:status]} at #{solution_status[:test]}"
          solution_status[:error].each {|x| ret_status[:error] << x }
        end
      end
      problem.save
    end


    #delete tmp
    FileUtils.rm_rf tmp_dir
    return ret_status    
  end


  def upd_problems_template
    self.problems.each { |problem| problem.use_template }
  end

end
