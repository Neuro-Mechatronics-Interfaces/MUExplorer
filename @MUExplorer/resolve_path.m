function p = resolve_path(p)
%RESOLVE_PATH Resolve .. and . in a path string
p = char(java.io.File(p).getCanonicalPath());
end
