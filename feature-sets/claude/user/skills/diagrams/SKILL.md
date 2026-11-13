---
name: diagrams
description: Draw a diagram in draw.io with the layout rules of the user, export it as an editable .drawio.svg, and check the render. Use when the user asks for a diagram, a figure, or a drawing, when a doc needs a picture of components, parties, or flows, or when another skill draws in draw.io.
---

# Diagrams

Draw each diagram in draw.io. Save it as a `.drawio.svg` with the diagram
embedded, so that the user can open and change it in draw.io.

If you find a new technique that gets a rule right, add it to this skill
at once. Change the skill freely: it collects what works.

## Layout

### Split

If a diagram needs more than about 12 boxes, or its edges must cross,
split it. A good cut is one diagram for the data path and one for the
control path.

### Reading direction

- A reader reads a diagram from left to right.
- Put the entry point in the left column. The entry point is the party or
  the component where the story starts, for example our own company or the
  client that sends the first request.
- Put the next steps in the columns to its right, in the order of the flow.

### Grid

- Place the boxes on a grid of columns and rows.
- Give the boxes of one column the same x and width. A column can be
  narrower than the others if its boxes hold little, for example a
  network that a path only crosses.
- Give the boxes of one row the same y and height.
- Leave enough room between two columns for the longest edge label
  between them. The gaps can differ from column to column.
- If a labeled edge runs between two rows, leave at least 40 px between
  them. With less, the label covers the whole line and the arrow tip
  vanishes.
- If the diagram has several bands, for example a band of services above
  a band of networks, put all bands on one column grid. A box in the top
  band then sits above a column of the band below.
- If a container in a band holds one box over two columns, stretch the
  box over both columns.

### Balance

Keep the outline of the diagram a rectangle. Give each column the same
height, and each row the same width.

If one column is shorter than its neighbors, the outline turns into a
diamond or a funnel. Its edges then fan out and run diagonal.

Three techniques balance a short column:

- Stretch a box over the height of the column it connects to. Each edge
  then leaves at the height of its target.
- Spread the boxes of the column over the rows of the boxes they connect
  to.
- Reorder the rows, so that connected boxes face each other.

Example: a vendor box connects to three customer boxes. The three
customers fill the middle column.

A small vendor box in the middle of the left column makes a diamond. A
vendor box from the top of the first customer to the bottom of the last
customer keeps the rectangle.

### Lines

- Draw an edge as a straight horizontal or vertical line.
- If a straight line is not possible, use right angles:
  `edgeStyle=orthogonalEdgeStyle;rounded=0`.
- Never draw a diagonal line.
- Set `endSize=10` on each arrow. The default tip of 6 is too small to see
  next to labels of `fontSize=14`.
- Pin each edge to a side of its boxes with `exitX`/`exitY` and
  `entryX`/`entryY`. Without the pins, the automatic routing picks
  diagonals and cuts through other boxes.
- If several edges leave one side, give each its own `exitY` or `exitX`,
  at the height or the position of its target.
- Route an edge that skips a column around the boxes with waypoints, for
  example along the top of the diagram.

### Labels

- Write a short label on each edge. Give it the same font size as the box
  labels, for example `fontSize=14` for both. A smaller edge label is hard
  to read next to the bold box labels.
- Put the label on its line, with a label background in the color behind
  it (`labelBackgroundColor`), so the line stops at the text.
- Pad the label with two non-breaking spaces on each side, for example
  `value="&amp;nbsp;&amp;nbsp;serves&amp;nbsp;&amp;nbsp;"`. The label
  background then leaves a gap between the line and the text.

  `spacingLeft` and `spacingRight` do not widen the background.
- If a label lands on a box title or a container border, move it along
  its edge. Set `x` on the `mxGeometry` of the edge, from `-1` at the
  source to `1` at the target.
- If an edge carries nested protocols, write the stack as a label with
  one line per layer, the innermost layer on top. Example: `TLS`,
  `CONNECT tunnel`, `QUIC`, `SCION/UDP`. Widen the gap for it, and move
  the label along the edge if it touches a border.
- If two relations connect the same two boxes, put them on one edge with
  a two-line label.
- Keep the label text in the words of the doc that holds the diagram.

### Conventions

- Give every shape the same corner radius:
  `rounded=1;absoluteArcSize=1;arcSize=14`. Without `absoluteArcSize`,
  `arcSize` is a percentage of the shorter side. A tall box or a
  container then gets far rounder corners than a small box.
- A solid arrow is a relation or a connection. A dashed arrow is a weaker
  relation, for example trust or control traffic.
- A hollow arrow head (`endArrow=block;endFill=0`) means "is a".
- A stacked box shows that many instances exist. Draw two copies of the
  box behind it, each with an offset of 8 px to the bottom right. Draw
  the copies first, so that the front box covers them, and pin the edges
  to the front box.
- Write the cardinality of a relation at both ends of its edge: `1`, `N`,
  or `M`, next to the box that the count is for. A stack alone does not
  tell 1:N from N:M.
- Make each count an end label, a child cell of the edge with
  `edgeLabel;resizable=0`. Set `x` to about `-0.9` at the source and
  `0.9` at the target. Set `verticalAlign=bottom` on a horizontal edge,
  and `align=left` on a vertical edge, so that the count sits beside the
  line.
- If the count lands on the copies of a stack, move it farther out along
  the edge.
- Give the main party, for example our own company, its own fill color.
- If the diagram shows components of several owners, give each owner
  one fill color, and add a legend row of colored boxes below the
  diagram. The color then replaces the containers.
- In an architecture diagram, a container shows where a component runs.
  The fill color shows who owns it.

  Give the container the stroke color of its owner and a light grey fill
  (`#fafafa`). Give the edge labels the same background
  (`labelBackgroundColor=#fafafa`), so a label in a container shows no
  white patch.
  - Make a container a real draw.io container (`container=1`), and give
    each child `parent="<container id>"` with coordinates relative to the
    container. The user can then move a container with its content.
  - Stack a container like a box. Its fill hides the copies behind it.
  - Leave at least 40 px between the top of a container and its first
    box, so the title has room below it.
  - If a vertical line enters a container from the top, pin it near the
    right edge of its boxes (`exitX` and `entryX` of about `0.9`). The
    title sits at the top left, so a centered line crosses it.
  - If one component has two sides, for example a router with a side for
    the endhosts and a side for the network, draw two boxes that share the
    column width, with a 20 px gap. Pin each edge to the side it belongs to.

    Put a small arrow (`endSize=6`) in the gap, from one side to the other.
    Mirror the halves where the flow enters from the other direction.
  - If boxes in a container share a role, for example the SCION
    endpoints of an AS, group them in a box of their own inside it. Give
    the group a dashed grey outline and a slightly darker grey fill, so it
    does not look like an owner.
  - Leave at least 30 px between a nested container, with its stack, and
    the border of its parent. Make the parent taller for this. Do not
    shrink the nested container, or its boxes stick out.
- Draw a network that many units reach, for example the Internet, as a
  flat bar between two bands. Do not draw it as a container: a unit runs
  in one place, but it can reach several networks.
  - Attach each unit with a plain vertical line (`endArrow=none`) at the
    center of its column.
  - A unit above the bar attaches to its top. A unit below attaches to
    its bottom.
- Draw a network, for example the Internet or the SCION network, with a
  darker grey fill (`#ececec`) and a dashed grey outline. It then stands
  apart from the containers.
- If a connection runs through a network, draw the network as a shape
  behind the arrow, not as a hop. The arrow then goes straight from one
  end to the other, across the network.
  - Draw the network before the edges, so the edges lie on top.
  - Put the network title at the top (`verticalAlign=top`), so the arrows
    leave it clear.
  - If the same network already has a bar, join the new shape to the bar,
    so the two read as one network. draw.io has no L or T shape.
    - Give both shapes a fill and no outline (`strokeColor=none`), and let
      them overlap by a few pixels. Draw the shape without the label first,
      so the label stays on top.
    - Draw the border as one closed line: an edge with `endArrow=none`,
      the same `sourcePoint` and `targetPoint`, and a waypoint at each
      corner of the joined shape. Start it in the middle of a side, so
      every corner gets the rounding of `rounded=1`.
- Give every shape a visible outline. The export has no page background,
  so a shape with only a fill disappears in a dark IDE.
- If the edges from one box are the steps of a sequence, number their
  labels, for example `1. log in`. Put the steps in rows from top to
  bottom.
- If a sequence runs over a layout that another diagram already has, for
  example the control path over the architecture, keep that layout. Put a
  numbered badge on the top left corner of each box in the sequence, and
  list the steps in the text below the figure.
  - A badge is a dark circle of 28 px with a white number:
    `ellipse;aspect=fixed;fillColor=#333333;fontColor=#ffffff`.
  - Add the badge to the legend.
- If two boxes in a container must connect past a third box, route the
  edge along the inner edge of the container with waypoints. Keep the
  lane clear of the badges.
- In a flow diagram, where nearly every edge is N:M, leave out the
  counts at the edge ends. The stacks are enough there.
- If the diagram uses more than two conventions, add a legend below it.
  Put the legend items next to each other with small gaps, in one or two
  rows. Do not spread them over the column grid.

## Export and check

draw.io needs a display. Xvfb gives it one.

If `ELECTRON_RUN_AS_NODE` is set, draw.io fails. The VS Code server sets
this variable, so unset it for each call.

```bash
Xvfb :99 -screen 0 1600x1200x24 >/dev/null 2>&1 & XPID=$!
export DISPLAY=:99
env -u ELECTRON_RUN_AS_NODE drawio --no-sandbox --disable-gpu \
  -x -f svg -e -o <out>/<name>.drawio.svg <scratchpad>/<name>.drawio
env -u ELECTRON_RUN_AS_NODE drawio --no-sandbox --disable-gpu \
  -x -f png -s 1.5 -o <scratchpad>/<name>.png <scratchpad>/<name>.drawio
kill $XPID
```

- The `-e` flag embeds the diagram in the SVG.
- Escape each label for XML, for example with
  `xml.sax.saxutils.escape`. A raw `<br>` in a `value` attribute makes
  draw.io stop at that cell. The render then shows boxes without text
  and without edges, and the SVG export hangs.
- If Xvfb fails, use the Wayland session of the user:
  `WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000` and
  `--ozone-platform=wayland` instead of `DISPLAY`.

Read the PNG, and check each rule:

1. The entry point is in the left column.
2. The outline is a rectangle, with no diamond or funnel.
3. No line runs diagonal.
4. No line crosses a box.
5. No label overlaps a line, a box, or another label.

Fix each finding, and export again. Tell the user to fix the fine layout
in the draw.io app.
