class DonutDogmatizer
  $schema_start = /DataPipelineArtifacts::\w*.new\(/
  $schema_end = /\)\n\s*end/
  def judge_schema(*args)
    relevant_filenames = []
    files_with_artifacts = []
    for file in args
      # Check if the file is in a directory starting with "data_pipeline_processors"
      next unless file.include?("/data_pipeline_processors/") && ["spec/", "/helpers/", "base_processor", "orchestrator", "/scripts/"].none? { |exclusion| file.include?(exclusion) }
      relevant_filenames << file
    end

    return unless relevant_filenames.any?

    relevant_filenames.each do |filename|
      if filename.end_with?(".rb")
        file_content = File.read(filename)
        if file_content =~ $schema_start
          files_with_artifacts << filename
          schema_start_line = file_content.index($schema_start) + $schema_start.source.length
          function_name = file_content[0..schema_start_line].split("\n").find_all { |line| line =~ /def / }[-1].strip
          diff_subsections = get_relevant_diffs(filename, [function_name])
          diff = get_entire_diff(filename)
          relevant_diff_sections = get_relevant_diffs(diff, [function_name])
          added_lines, removed_lines = get_only_changed_lines(relevant_diff_sections)
          was_version_bumped = check_if_version_bumped(diff)
          change_type = get_change_type(added_lines, removed_lines)
          if !was_version_bumped
            if change_type == "removed"
              raise "You appear to have removed a part of a JSON schema without bumping the version! Please bump the version, or skip this check and suffer the consequences..."
            elsif change_type == "changed"
              raise "Your changes appear to have changed a JSON schema without bumping the version! If this change is NOT backwards compatible, please bump the version, or skip this check and suffer the consequences... but if it is backwards compatible, just ignore this check :^)"
            elsif change_type == "added"
              pp "The donuts deem this change... backwards compatible!"
            end
          else
            pp "Thanks for bumping the schema version!"
          end
        else
          pp "File: #{filename} does not generate Artifacts."
        end
      else
        puts "File: #{filename} is not a Ruby file."
      end
    end
  end

  def get_entire_diff(file_to_diff)
    IO.popen("git diff HEAD~1 -- #{file_to_diff}") do |io|
      diff = io.read
      diff
    end
  end
  def get_relevant_diffs(diff, containing_functions)
    containing_functions.each do |containing_function|
      start_pattern = /#{containing_function}\s*/
      end_pattern = /@@|def/ # either the next @@ from the diff, or the next function definition
      # remove the first @@/end pattern
      diff = diff[diff.index(end_pattern)..-1]

      relevant_diff_sections = []
      diff_section_starts = diff.scan(start_pattern)
      diff_section_starts.each do |diff_start|
        end_of_start = diff.index(start_pattern) + diff_start.length
        end_index = diff.index(end_pattern, end_of_start)
        relevant_diff_sections << diff[end_of_start...end_index]
        # chop off the part we just put into the above array
        diff = diff[end_index..-1]
      end
      if relevant_diff_sections
        return relevant_diff_sections
      else
        return []
      end
    end
  end

  def get_change_type(added_lines, removed_lines)
    if removed_lines.length > added_lines.length
      pp "Your changes appear to removed something from a JSON schema. Please ensure the schema version has been updated."
      pp "Skip this check with SKIP=donut-dogmatizer"
      "removed"
    elsif added_lines.length == removed_lines.length
      pp "Your appear to have changed #{added_lines.length} lines of a JSON schema. Please check if this change is backwards compatible. If it's not, bump the schema version!"
      pp "Skip this check with SKIP=donut-dogmatizer"
      "changed"
    elsif removed_lines.length == 0
      pp "Your changes appear have only added a new line to the JSON schema. This shouldn't require a version bump!"
      "added"
    else
      pp "You appear to have changed #{removed_lines.length} lines of a JSON schema. Please check if this change is backwards compatible. If it's not, bump the schema version!"
      pp "Skip this check with SKIP=donut-dogmatizer"
      "changed"
    end
  end

  def get_only_changed_lines(diff_subsections)
    added_lines = []
    removed_lines = []
    diff_subsections.each do |diff_subsection|
      lines = diff_subsection.split("\n")
      lines.each do |line|
        # Check if the line starts with a "+" or "-" and is not a comment
        if line.start_with?("+") && !line.start_with?("++") && !line.start_with?("#")
          added_lines << line[1..-1].strip
        elsif line.start_with?("-") && !line.start_with?("--") && !line.start_with?("#")
          removed_lines << line[1..-1].strip
        end
      end
    end
    [added_lines, removed_lines]
  end
  def check_if_version_bumped(diff)
    # Check if the file has a version bump
    if diff =~ /def version/
      version_diff = diff[diff.index(/def version/)...diff.index(/end|@@|def/)]
      if version_diff && version_diff.match(/\+ *v\d+/) && version_diff.match(/- *v\d+/)
        added_version = version_diff.match(/\+ *v\d+/).scan(/\d+/).join
        removed_version = version_diff.match(/- *v\d+/).scan(/\d+/).join
        if added_version.to_i > removed_version.to_i
          true
        end
      else
        false
      end
    else
      false
    end
  end
end

