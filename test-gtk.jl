using Gtk.ShortNames

win = @Window("A new window")
g = @Grid()   # gtk3-only (use @Table() for gtk2)
a = @Entry()  # a widget for entering text
setproperty!(a, :text, "This is Gtk!")
b = @CheckButton("Check me!")
c = @Scale(false, 0:10)     # a slider
# Now let's place these graphical elements into the Grid:
g[1,1] = a    # cartesian coordinates, g[x,y]
g[2,1] = b
g[1:2,2] = c  # spans both columns
setproperty!(g, :column_homogeneous, true) # setproperty!(g,:homogeoneous,true) for gtk2
setproperty!(g, :column_spacing, 15)  # introduce a 15-pixel gap between columns
push!(win, g)
showall(win)