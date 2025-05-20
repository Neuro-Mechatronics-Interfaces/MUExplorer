function config = readSimpleYAML(yamlFile)
%READSIMPLEYAML Minimal YAML parser for key: value and list-of-maps formats
%   Returns a struct suitable for config loading in MUExplorer, etc.

fid = fopen(yamlFile, 'r');
if fid == -1
    error('Cannot open file: %s', yamlFile);
end
rawLines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
lines = strtrim(string(rawLines{1}));

fclose(fid);

config = struct();
i = 1;
while i <= numel(lines)
    line = lines(i);

    % Skip empty lines and comments
    if line == "" || startsWith(line, "#")
        i = i + 1;
        continue;
    end

    % Handle list-of-maps block (e.g., Grids:)
    if endsWith(line, ":") && ~contains(line, " ")
        key = extractBefore(line, ":");
        i = i + 1;
        items = [];
        while i <= numel(lines) && startsWith(strtrim(lines(i)), "- ")
            % Collect fields in this block
            item = struct();
            while i <= numel(lines) && (startsWith(strtrim(lines(i)), "- ") || contains(lines(i), ":"))
                curr = strtrim(lines(i));
                if startsWith(curr, "- ")
                    curr = extractAfter(curr, 2);  % remove "- "
                end
                if contains(curr, ":")
                    [subkey, val] = strtok(curr, ":");
                    val = strtrim(extractAfter(val, ":"));
                    numval = str2double(val);
                    if ~isnan(numval)
                        val = numval;
                    end
                    item.(strtrim(subkey)) = val;
                else
                    break;
                end
                i = i + 1;
                if i > numel(lines), break; end
                if startsWith(lines(i), "- "), break; end
            end
            items = [items, item]; %#ok<AGROW>
        end
        config.(key) = items;
        continue;
    end

    % Handle flat key: value line
    if contains(line, ":")
        [key, val] = strtok(line, ":");
        val = strtrim(extractAfter(val, ":"));
        numval = str2double(val);
        if ~isnan(numval)
            config.(strtrim(key)) = numval;
        else
            config.(strtrim(key)) = val;
        end
    end
    i = i + 1;
end
end
