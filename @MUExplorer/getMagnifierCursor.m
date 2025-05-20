function cursor = getMagnifierCursor()
% Returns a simple magnifier shape (16x16)
cursor = NaN(16);  % transparent background
[x, y] = meshgrid(1:16, 1:16);
r = sqrt((x-7).^2 + (y-7).^2);
cursor(r > 3 & r < 5) = 1;  % circle
cursor(11:14, 11:14) = 1;   % handle
end