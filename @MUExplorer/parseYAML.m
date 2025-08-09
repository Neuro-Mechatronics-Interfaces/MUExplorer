function config = parseYAML(yamlFile)
%PARSEYAML  YAML parser for flat keys, nested maps, and list-of-maps.
%
%   config = MUExplorer.parseYaml(yamlFile) reads a simplified YAML file and returns
%   a struct CONFIG. Supported constructs (2-space indentation assumed):
%
%   1) Flat key-value:
%        Key: Value
%
%   2) Nested map (struct):
%        BlockName:
%          KeyA: ValA
%          KeyB: ValB
%
%   3) List of maps (array of structs):
%        BlockName:
%          - Field1: Val1
%            Field2: Val2
%          - Field1: Val3
%            Field2: Val4
%
%   Parsing details:
%     • Inline comments are stripped after the first unquoted '#'.
%     • Numeric strings are converted to double when possible.
%     • Booleans: true/false/yes/no/on/off (case-insensitive) → logical.
%     • Quoted strings may contain '#' which won’t start a comment.
%     • This is NOT a full YAML parser (no multi-level nesting beyond the above).
%
%   Example:
%       cfg = readSimpleYAML('config.yaml');
%       cfg.InitialProcessingParameters.UseRobustScale  % -> logical true
%       cfg.Grids(1).Name                               % -> "P-EXT"

    fid = fopen(yamlFile, 'r');
    if fid == -1
        error('Cannot open file: %s', yamlFile);
    end
    rawLines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);

    lines = string(rawLines{1});

    % --- Preprocess: strip inline comments (respecting quotes) + rtrim
    for k = 1:numel(lines)
        lines(k) = rstrip(stripInlineCommentRespectQuotes(lines(k)));
    end
    % Drop empty/whitespace-only lines
    lines = lines(strlength(strtrim(lines)) > 0);

    config = struct();
    i = 1;
    while i <= numel(lines)
        line = lines(i);
        indent = leadingSpaces(line);
        tline  = strtrim(line);

        % Top-level flat key: value
        if indent == 0 && contains(tline, ":") && ~endsWith(tline, ":")
            [key, val] = splitOnce(tline, ":");
            config.(sanitizeKey(key)) = parseScalar(val);
            i = i + 1;
            continue;
        end

        % Top-level block header: "Key:"
        if indent == 0 && endsWith(tline, ":")
            blockKey = sanitizeKey(extractBefore(tline, ":"));
            i = i + 1;

            % Peek: are we entering a list-of-maps (lines starting with "- ") or a nested map?
            if i <= numel(lines)
                nextLine = lines(i);
                nextTrim = strtrim(nextLine);

                if startsWith(nextTrim, "- ")
                    % -------- List of maps --------
                    items = struct([]); % array of structs
                    while i <= numel(lines)
                        % Each item must start with "- "
                        cur = lines(i);
                        if ~startsWith(strtrim(cur), "- ")
                            break; % end of list
                        end
                        itemIndent = leadingSpaces(cur);
                        cur = strtrim(cur);
                        % Remove "- "
                        curAfterDash = strtrim(extractAfter(cur, 2));

                        item = struct();

                        % Case: "- Key: Val" on the same line
                        if contains(curAfterDash, ":")
                            [subk, subval] = splitOnce(curAfterDash, ":");
                            item.(sanitizeKey(subk)) = parseScalar(subval);
                        end
                        i = i + 1;

                        % Consume following indented "key: val" lines that belong to this item
                        while i <= numel(lines)
                            nxt = lines(i);
                            if leadingSpaces(nxt) <= itemIndent
                                break; % out of this item
                            end
                            nt = strtrim(nxt);
                            if startsWith(nt, "- ")
                                break; % next item begins
                            end
                            if contains(nt, ":")
                                [subk, subval] = splitOnce(nt, ":");
                                item.(sanitizeKey(subk)) = parseScalar(subval);
                                i = i + 1;
                            else
                                break;
                            end
                        end

                        if isempty(items)
                            items = item; % initialize
                        else
                            % Ensure consistent fields by union (fill missing with [])
                            items = unifyStructArray(items, item);
                        end
                    end
                    config.(blockKey) = items;
                    continue;

                else
                    % -------- Nested map (struct) --------
                    nested = struct();
                    while i <= numel(lines)
                        cur = lines(i);
                        if leadingSpaces(cur) == 0
                            break; % next top-level key
                        end
                        nt = strtrim(cur);
                        if ~contains(nt, ":") || startsWith(nt, "- ")
                            break; % not a simple key:val in this nested block
                        end
                        [subk, subval] = splitOnce(nt, ":");
                        nested.(sanitizeKey(subk)) = parseScalar(subval);
                        i = i + 1;
                    end
                    config.(blockKey) = nested;
                    continue;
                end
            else
                % Empty block → empty struct
                config.(blockKey) = struct();
                continue;
            end
        end

        % If none matched, advance to avoid infinite loop
        i = i + 1;
    end
end

% -------- Helpers --------

function s = stripInlineCommentRespectQuotes(s)
    % Remove text after first unquoted '#'
    % Always return a 1x1 string scalar.
    if strlength(s) == 0
        s = "";  % ensure string scalar, not empty array
        return;
    end
    inS = false; inD = false;
    ch = char(s);
    out = char.empty(1,0);
    for idx = 1:numel(ch)
        c = ch(idx);
        if c == '"'  && ~inS
            inD = ~inD; out(end+1) = c; %#ok<AGROW>
        elseif c == '''' && ~inD
            inS = ~inS; out(end+1) = c; %#ok<AGROW>
        elseif c == '#' && ~inS && ~inD
            break; % start of comment
        else
            out(end+1) = c; %#ok<AGROW>
        end
    end
    s = string(out);         % ensure string
    if strlength(s) == 0
        s = "";              % normalize to empty string scalar
    end
end

function n = leadingSpaces(s)
    % Count leading spaces (tabs treated as 2 spaces)
    s = char(s);
    n = 0;
    for k = 1:numel(s)
        if s(k) == ' '
            n = n + 1;
        elseif s(k) == sprintf('\t')
            n = n + 2;
        else
            break;
        end
    end
end

function s = rstrip(s)
    % Remove trailing whitespace only; always return a string scalar.
    if ~isa(s,'string'); s = string(s); end
    s = regexprep(s, '\s+$', '');
    if strlength(s) == 0
        s = "";              % normalize
    end
end


function [k, v] = splitOnce(s, delim)
    pos = strfind(s, delim);
    if isempty(pos)
        k = strtrim(s);
        v = "";
        return;
    end
    k = strtrim(extractBefore(s, pos(1)));
    v = strtrim(extractAfter(s, pos(1)));
end

function key = sanitizeKey(k)
    % Make a valid MATLAB struct field (remove quotes, spaces -> underscores)
    k = stripQuotes(k);
    k = regexprep(k, '\s+', '_');
    k = regexprep(k, '[^\w]', '_'); % keep [A-Za-z0-9_]
    if isempty(k)
        k = "field";
    end
    key = char(k);
end

function val = parseScalar(v)
    % Strip surrounding quotes if present
    v = stripQuotes(v);

    % Numeric?
    numval = str2double(v);
    if ~isnan(numval)
        val = numval;
        return;
    end

    % Logical?
    lv = lower(strtrim(v));
    if any(strcmp(lv, ["true","yes","on"]))
        val = true;  return;
    elseif any(strcmp(lv, ["false","no","off"]))
        val = false; return;
    end

    % Otherwise string
    val = char(v);
end

function v = stripQuotes(v)
    v = string(v);
    if strlength(v) >= 2
        if (startsWith(v, '"') && endsWith(v, '"')) || (startsWith(v, '''') && endsWith(v, ''''))
            v = extractBetween(v, 2, strlength(v)-1);
        end
    end
end

function A = unifyStructArray(A, B)
    % Ensure concatenation works even if fields differ between items.
    if isempty(A)
        A = B; return;
    end
    fA = fieldnames(A); fB = fieldnames(B);
    addToA = setdiff(fB, fA);
    addToB = setdiff(fA, fB);
    % Add missing fields to A (all elements)
    for k = 1:numel(addToA)
        [A.(addToA{k})] = deal([]);
    end
    % Add missing fields to B
    for k = 1:numel(addToB)
        B.(addToB{k}) = [];
    end
    A(end+1) = B;
end
