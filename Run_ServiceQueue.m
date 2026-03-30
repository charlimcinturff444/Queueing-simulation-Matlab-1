%[text] # Run samples of the ServiceQueue simulation
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in hours
%[text] Arrival rate: 10 per hour
lambda = 10;
%[text] Departure (service) rate: 1 per 5 minutes, so 12 per hour
mu = 12;
%[text] Number of serving stations
s = 1;
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 96;
%[text] Make a log entry every so often
LogInterval = 1/60;

%[text] 
%%
%[text] ## Numbers from theory for M/M/1 queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
%rho = lambda / mu;
%P0 = 1 - rho;
%nMax = 10;
%P = zeros([1, nMax+1]);
%P(1) = P0;
%for n = 1:nMax
 %   P(1+n) = P0 * rho^n;
%end


%M/M/2
lambaBank = 40;
muBank = 30;
channels = 2;
numSamples = 100;
maxTimeHours = 8;


%M/M/2 Simulation
aBank = lambaBank/muBank;

rhoBank = lambaBank /(channels*muBank);

nMax = 10;
PBank = zeros([1,nMax +1]);

pTerm = 0;

for n = 0:(channels-1)
    pTerm = pTerm + aBank^n / factorial(n);
end

pZero = 1 / (pTerm + (aBank^channels / factorial(channels)) * (1/ (1-rhoBank)));
P(1) = pZero;

for n = 1:nMax
    if n < channels
        P(n+1) = pZero * aBank ^n / factorial(n);
    else
        P(n+1) = pZero * aBank^n /(factorial(channels) * channels^(n - channels));
    end
end
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([numSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:numSamples %[output:group:7717dfe7]
    fprintf("Working on sample %d\n", SampleNum); %[output:12a7dfbd]
    q = ServiceQueue( ...
        ArrivalRate=lambaBank, ...
        DepartureRate=muBank, ...
        NumServers=channels, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, maxTimeHours);
    QSamples{SampleNum} = q;
end %[output:group:7717dfe7]
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop.
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};

NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

NumInSystem = vertcat(NumInSystemSamples{:});

meanNumInSystem = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:4bcc5a1f]

fig = figure(); %[output:84a2c8b5]
t = tiledlayout(fig,1,1); %[output:84a2c8b5]
ax = nexttile(t); %[output:84a2c8b5]
hold(ax, "on"); %[output:84a2c8b5]

histogram(ax, NumInSystem, ... %[output:84a2c8b5]
    Normalization="probability", ... %[output:84a2c8b5]
    BinMethod="integers"); %[output:84a2c8b5]

plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:84a2c8b5]

title(ax, "Number of customers in the system"); %[output:84a2c8b5]
xlabel(ax, "Count"); %[output:84a2c8b5]
ylabel(ax, "Probability"); %[output:84a2c8b5]
legend(ax, "simulation", "theory"); %[output:84a2c8b5]

ylim(ax, [0, 0.3]); %[output:84a2c8b5]
xlim(ax, [-1, 20]); %[output:84a2c8b5]


%[text] ### Option two: Map a function over the cell array of ServiceQueue objects.
%[text] The `@(q) ...` expression is shorthand for a function that takes a `ServiceQueue` as input, names it `q`, and computes the sum of two columns from its log.  The `cellfun` function applies that function to each item in `QSamples`. The option `UniformOutput=false` tells `cellfun` to produce a cell array rather than a numerical array.
NumInSystemSamples = cellfun( ...
    @(q) q.Log.NumWaiting + q.Log.NumInService, ...
    QSamples, ...
    UniformOutput=false);
%[text] ## Join numbers from all sample runs.
%[text] `vertcat` is short for "vertical concatenate", meaning it joins a bunch of arrays vertically, which in this case results in one tall column.
NumInSystem = vertcat(NumInSystemSamples{:});
%[text] MATLAB-ism: When you pull multiple items from a cell array, the result is a "comma-separated list" rather than some kind of array.  Thus, the above means
%[text] `NumInSystem = vertcat(NumInSystemSamples{1}, NumInSystemSamples{2}, ...)`
%[text] which concatenates all the columns of numbers in NumInSystemSamples into one long column.
%[text] This is roughly equivalent to "splatting" in Python, which looks like `f(*args)`.
%%
%[text] ## Pictures and stats for number of customers in system
%[text] Print out mean number of customers in the system.
meanNumInSystem = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:0015ecf7]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:853c9768]
t = tiledlayout(fig,1,1); %[output:853c9768]
ax = nexttile(t); %[output:853c9768]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:853c9768]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:853c9768]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:853c9768]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:853c9768]
xlabel(ax, "Count"); %[output:853c9768]
ylabel(ax, "Probability"); %[output:853c9768]
legend(ax, "simulation", "theory"); %[output:853c9768]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.3$.
ylim(ax, [0, 0.3]); %[output:853c9768]
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]); %[output:853c9768]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Number in system histogram.pdf"); %[output:853c9768]
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample `ServiceQueue`.
%[text] ### Option one: Use a for loop.
TimeInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list `q.Served` and compute the time it spent in the system.
TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);
%[text] ### Join them all into one big column.
TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] Print out mean time spent in the system.
meanTimeInSystem = mean(TimeInSystem);
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:67d64d7d]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:0d80950b]
t = tiledlayout(fig,1,1); %[output:0d80950b]
ax = nexttile(t); %[output:0d80950b]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:0d80950b]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:0d80950b]
xlabel(ax, "Time"); %[output:0d80950b]
ylabel(ax, "Probability"); %[output:0d80950b]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:0d80950b]
xlim(ax, [0, 8]); %[output:0d80950b]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf"); %[output:0d80950b]

%%
%[text] #### **Part A**
%[text] $L = \\frac{10}{12 - 10} = 5\n$
%[text] $L\_q = \\frac{10}{12(12 - 10)} = \\frac{10}{24}$
%[text] $W = \\frac{5}{10}=.5$
%[text] $W\_q = \\frac{10}{10 \\cdot 2}=.5$
%[text] 
%[text] $\\%\\text{L discrepancy} = \\left| \\frac{4.808672 - 5}{5} \\right| \\times 100\\%\n= \\left| \\frac{-0.191328}{5} \\right| \\times 100\\%\n= 0.0382656 \\times 100\\%\n= 3.82656\\%$
%[text] 
%[text] $\\%\\text{W discrepancy} = \\left| \\frac{0.480263 - 0.5}{0.5} \\right| \\times 100\\%\n= \\left| \\frac{-0.019737}{0.5} \\right| \\times 100\\%\n= 0.039474 \\times 100\\%\n= 3.9474\\%$
%%
%[text] #### **Part B**
%[text] **a)**
%[text] $\\begin{array}{l}\n\\lambda =40\\\\\n\\mu =30\n\\end{array}${"editStyle":"visual"}
%[text] $\\rho =\\frac{40}{60}=\\frac{2}{3}${"editStyle":"visual"}
%[text] $P\_o ={\\left(1+\\frac{\\left(\\frac{4}{3}\\right)}{2!}\*\\frac{1}{1-\\left(\\frac{2}{3}\\right)}\\right)}^{-1} =\\frac{1}{5}${"editStyle":"visual"}
%[text] $P\_1 =\\frac{\\left(\\frac{4}{3}\\right)}{1}\*\\frac{1}{5}=\\ldotp 2667${"editStyle":"visual"}
%[text] $P\_2 ={\\frac{\\left(\\frac{4}{3}\\right)}{2!}}^2 \*\\frac{1}{5}=\\ldotp 1778${"editStyle":"visual"}
%[text] $P\_3 =\\frac{{\\left(\\frac{4}{3}\\right)}^3 }{2!\*2}\*\\frac{1}{5}=\\ldotp 1185${"editStyle":"visual"}
%[text] $P\_4 =\\frac{{\\left(\\frac{4}{3}\\right)}^4 }{2!\*2^2 }\*\\frac{1}{5}=\\ldotp 0794${"editStyle":"visual"}
%[text] $P\_5 =\\frac{{\\left(\\frac{4}{3}\\right)}^2 }{2!2^3 }\*\\frac{1}{5}=\\ldotp 0527${"editStyle":"visual"}
%[text] 
%[text] **b)**
%[text] $L=1\\ldotp 0667+\\left(\\frac{40}{30}\\right)=2\\ldotp 4${"editStyle":"visual"}
%[text] $L\_q =40\*\\ldotp 02667=1\\ldotp 0667${"editStyle":"visual"}
%[text] $Wq =\\frac{{40}^2 }{30\\left(4\*{30}^2 -{40}^2 \\right)}=\\ldotp 02667${"editStyle":"visual"}
%[text] $W=\\frac{L}{\\lambda }=\\frac{2\\ldotp 4}{40}=0\\ldotp 06${"editStyle":"visual"}
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":18.5}
%---
%[output:12a7dfbd]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:4bcc5a1f]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 2.411223\n","truncated":false}}
%---
%[output:84a2c8b5]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAATsAAAC+CAYAAABK1qgYAAAAAXNSR0IArs4c6QAAIABJREFUeF7tXXuMFlWWP8ywRlCz2kgU8NE+wN2JDqxulKDExqzxn4GMggP0BkKLhDE+iDzkIRHUBQFhkwENsEg+GGZ5jAqGnsjMutAgM6ya4AwaZzLi4xNoiGlf8QFG22Vzyj3f3L59q+rWV++qXyVE+6uq+\/idc391zr3nntvj9OnTpwkXEAACQKDgCPQA2RVcwugeEAACDgIgOygCEAACpUAAZFcKMaOTQAAIgOygA0AACJQCAZBdKcSMTgIBIACygw4AASBQCgRAdqUQMzoJBIAAyA46AASAQCkQANmVQszoJBAAAiA76AAQAAKlQABkVwoxo5NAAAiA7KADQAAIlAIBkF0pxIxOAgEgALKDDgABIFAKBEB2pRAzOgkEgADIDjoABIBAKRDIFdlt27aN5s6dS\/3796dKpUIDBw6sCUnujRw5kpYsWUK9evWKVYBLly6ltWvX0tSpU2n27Nmx1hW0cMGC3zNhFbS8sM9\/8skn9Oijj9KCBQuooaEhbHGZep\/7NnnyZDp06BBt3ryZhg4dGqp9LDu+xo4d6\/w3y3oWpKPcj5tvvjk0PkHq1J\/NJdlxJ3SSAdl9L9rDhw9TS0sLHT9+3Pl78ODBtH79+tRIRtrTt2\/fVNsRZpB4vRsl2QmxPfHEE4Uhu1OnTtGcOXOotbU1ko9BGDnmluy40+qXFGTXleyyQi5FJ7swg09\/F2QXJZrdy8o12akuq052x44dcywcvlSXV3cLVAWrVquOa8qXfF3lvvqb7l7w3\/KeyY1Wy9DdSrnH7x05csRxh7xc41deeYWam5trkjRhoIrZqyzV3dX7Z\/p4mKwY9TepVz5Celt1i9yrLyrGLIsgsjFZuCoOQsD8XFNTk\/PRFLn06dOn5pbq\/TENRRMmqo41NjY6Uy9eVrZq\/Ugd0p7t27fXpkvYDRTZmyx2Lz0ztV33AlTddDMe9I8XlytuvI6XSTfUduv6ZzJeWG4qhiJH9V3bqaRckh0D1tHR4bhqQkphyU5XBhY8W0dMPuolAlEVS39XCIh\/FxNef8arHNWNUd\/TlUPuiQK99NJLtYEl99wUwa39bnjyHKg+sAcNGtRN0VWF5\/9XiVklO7++8NyeWxv9ZGMiWa5b5CIfQnH1hYiefPJJmjVrVjeZ8323+TgvsjMRjOljaEN2XmXZ6Jn+vk50OskK6fM4U40FkRvr1ZQpUzzlb9IP0dV169bVDAS1bbr+mfo9fPhw2r9\/f5dbbmNGfSiXZMcKM2TIEHr88cdrc1Iy0HWF5s7aWHYiBPVLZfpNt\/jUr6E6yHhwyGBXFVyekd9WrlzpCN1vIUFVTmmDOkiE1GzcRrUs3QrTiVNtuz6weUCw9ay6zLrlbGqPbV+krCCyGTVqVLc5In3eSNrNZGey+Lz6ow8+L7IzWUpecvZyY016Jr99\/PHHzkfFS8\/0BTtdD1XC1HVc17eDBw86Y4ovP\/mb5uy8dEKwl\/EsfbzoootqcjX9ZmPd5ZbseGWPV\/h44lM1deslOxUs0wqYroimZ1TB6q6XPkj0L5yfsNzcClFaKY8VX1dAvW5d0U0r1zZurP7lNrlWJsW27Yt8\/YPI5tprr+2yQKP3neUiz+gfQt3tslnc8XNjZaVedZ31SAJpo+2cnV6WuLomK8itD7plZ7I4dT0Ri\/i6665zIh5Y31UX1lSXiezcrHpuvxDZ66+\/7ngpXlNVrLeqpekXFZFbsmOw2cXkLxoDJHMv9ZKdaQXM6zeTYrKw3OYAdUU0zcl4CctNqDqZ2JCdzWKODdlxmIWbyyjYeZGdTvD6s0J2QWTjR3Zc5x133GGcz2UZ+fUniGXnNk+YJNl5WZJupCPWvhC5uLJCqqo8\/PAKSnYyZfDBBx84ZKdiaBoDpSE7ZnZ9XidpslOF4WbZeVlttnFUttaQDdlFZdnpMWWqteBladr2JQzZ6VabSlI2VhY\/b+qPHieYJcvOzzswWX7ym0paqjUl+jl9+nTavXu3M1fuRtYmvHiM6qEnQT62IDslcNjNHFcnoeVLpT4rIHq5DjaWnc1citcql8zZ+Smq7TxXvXN2OgGIG+G2eqbOSarP6OXIvI5KPrZ9qUc26pydYOo216gToj4lwMTmR4xxkJ2f2663SebsbFZThdxMhGPqv265qW2zwUuda9OtfZ4z9ZszBtlpuyRUc9xmJZQFHhXZmb6WNm3QV2P9yE51kd3m\/9TB6Rdn57bSqS90qCuWar3cfiY5t9Vmt5VPfWHGqy\/1kB3vPLBdjdXJzrQqKu1z25kTB9lJnYzxvn37uu3U0clOJRQdT5tVZP0dN29FXEyx6G3w4ndUHdGnb0xzqixDW5e1VG4sg6UqnNvqoRAc\/1fd5lXvgFLdTymT\/6sPCpNCqApo68aa3A1TfTaWnf51l791wtVJ46mnniJ2LdWtUab+6eWYPkbs3gSJs9O3T\/nN43mV7WWt2fRHHaBRkp2+QGJLdrxt0k\/PTB9lUxycKYRD5Oe3AOGmR6olr1qf+gdXrbvUZKcOGL9VMl3wNjE4XvMZuAcEyoxA0A9yVrHKxWosf6UZcNnjycR34MAB44Z\/ITr+gvDqpny9+P\/DbtLOqhDRLiAQNQK6weAXBxp1\/XGUl3myE9CHDRtW2xzNBDZjxgyaN29el8wnDBCbzA899BAtW7asdo+Jki+\/OJw4AEaZQCCvCKhuZhQZXdLGIfNkZ7LMTAToBiQsu7RVDPUDgWwgkAuyM1lx\/NXhDcIyca3DadpKZYKcQ1T4H69o8T9cQAAIFBOBwpKdKi63OT4mOd74\/eqrr9K0adOcf7iAABAoJgK5IDvef6cuMARxY93m8fh3CU\/gbBc33HADLLti6jh6BQQcBDJPdkEXKPSVWxuyK8LkK\/QZCAABbwQyT3ZigQUNPZHVWz0URYVDLDuQHYYJECg+ArkgOxaDV1CxPienR4a7bcUC2RVfwdFDICAI5Ibs4hAZyC4OVFEmEMgmAiC75uZITj3iMxI2btxIe\/fupWPVKnUS0aRJk5zjA3EBASCQPgIguwjIjonu1hEjaFG1Snfyqg8RnSaiZ4no4cZGWlepOMlFcQEBIJAeAiC7kGQnRPdatUrnGeT4KRFd39hIh99\/Pz0po2YgAASyH3oSp4yimLPbsGED9W5poZ95NPTXRHSyUnHcWlxAAAikgwAsuxCWHe\/AmDBhAu3Zu9dxXd0udmlvaWqitra2dKSMWoEAEIBlxwf21BNnJ1vNXnjuOTrVycsR3levnj0dVxb7b\/2Qwn0gEA8CsOzqJDtxgY8ePUrfdHb6Wna9zzzTseyQUy8eRUapQMAPAZBdSLI776qhNPu3W3zn7Kaeey7t2rWrNGQn2WT8FBD384tA3jIFgexCkt2NU5fSiysepHc62l1XY\/v37En9Lr64Lnc5j0NBzSaTx\/ajzXYIcPIMTqKRl6kZkF0EZHfGOX3ohYUTaXVHe7c4u3v6DqCbJsykN3esLA3ZqdlkBgwYYDdy8FSuEOC0aL\/4xS9ypdMguwjI7vzLf0yfd7TTn\/fuoGNvvUYnO9qdHRQ\/arqdht55H3303hv0h7Wzc6UYYUZeFCE9YerHu\/EjkEcZg+wiIjsv9QLZfY9OUebx8jZXFQf1gexcUFWzkGTpWMMwApN3ec6OLTuQ3d8QMOHKRHf3vQ\/S228ejGPsJVpm3uaq4gAnzNiJoz02ZSZq2alpmrhxaRNfGIGB7NzVy4Sr\/PZPP5tOvc+7wEY3M\/nMR+++QX\/97\/+0npKI+mQ70+l5NkBF3Y4wY8emvXE8kyjZqR3IAvGFERjIrj6ys7GE41D0qMoMOiURNcnYkp3+XNTtCDN2opJF0HJSIztpqE56gwcPrh2GHbQzQZ8PIzCQHcgujQDxesku6Njwez7M2PErO677iZOd10njco87y8vacV9hBAayA9mpZKceKD1y5EhasmQJ9erVi8SieuCBB2jOnDnOwe27d++mQ4cOET9311130b333kvHjx93\/ub3+J56DIFKcIy6egi86KFIg6eGbr31VuJDqric\/v37U6VSoe3btzuPyEHxanslk7eMv3POOcfJy8htcjM+woyduMe1W\/mJkJ2eJp0b47YfVQ7M2bFjR+yYhBEYyA5kJ2THurBly5YuBCdnGutkd+TIEcdz4YsJ6ZJLLnHe4wWclpYWWr58uXPPhuz69OlD6pnKMna4\/I8\/\/rgLKapurHqMARMct2PcuHE0atQoh5CljUzW\/DcTppCkSD3M2Il9YLtUkCjZMaBuh1qnAUAYgYHsQHYq2bkllNDJTj8ISv4Wg0C1vJi0GhoayMuyU6XAJLZ161aHTN3ITixMqZffF\/J75JFH6LHHHiP1nttcX5ixk8ZY5zoTIzv1C6R3Vv0isXCTusIIDGQHslPdWN2dFM8lTrLjeD+2vFpbWx1hDB8+nD7\/\/HNPspsyZYpjyannMIPsImQc\/mp5kZ36RQLZRQh8SkV5hZ6UYTVW1ed169Y5UtAtKv085HosO7beVHfXxo2FZRfToFAnQf2qSCPmDpadn1Tqu182stOP8lTn8FauXBmY7HguTubv2Hrk8letWuUsNPAlCxRMdjNnznR+FytP5tvCzNnBja1P7523\/Cy7EEWHehVkFwo+15e9yO6qf\/lXOv8K7x0n8bQqmlJPfvoh\/fHX\/95tgU39sMsKKK+81uPGMsGp5U2fPp0OHjxI8+bN60J2qhvLdfJ9tiSXLVtWIz92cdml3rdvn\/OuzWosyC4aXclUKSC7eMRhwrVIaZ+wXYwozNiJR+v8S41tgULmIHgFVo37cWuSXzCxGnzs96we6iJxRHrdfgLzOgsWCxTuyuWGKxIB+A\/IvDzhN3ay2I\/YyC7KzuqrtfociVqXSrIc5qJPBKvPegnM7yzYu3\/+c1q7di3ZTLgH3WIUJXZplJXHgZAGTnmuM48yzjzZmcjKaw7QFMaiB32KkrkJzPYs2O969ADZGUZsHgdCnoknjbbnUcaZJzt1SV7imrysNZPg3SxBt7mle+65hyb85je+50rc17cv3TbjaaR40kDP40BIgzDyXGceZRwb2Zm2iHkJ120ezs2K49Uq2ZLjVa6JLHXLbtq0aTR69GhnBYuFOGLECDr59ddWJ4aNWfhLkF3KZOc1t5oGoUSdYSSNPvjVCbLzQ6iO+2HIToiOLUJ9bx83RY16Z8Ljfw7ZDR9ufRbsmH\/bDLJLkez85lbXVSrU1NRUh+bZv6J\/UEF29tgl+WRsll1UnajXjfUjOpXs+IQkDicQy4633dieBQvLrrukk\/rq286t8uHkcV4gu6FxwhtZ2bGRXVShJ0EXKBgZ3jjNEej333+\/Z+IBt+BXzv7wVEeH75wdnwX7kzn\/AcsuJctuw4YN1LulxVdOJysVmjRpUmSDRi+IPQLZnyoBvF988QXxP\/5dDTJW9ZNTKNneY13l1X95\/8Ybb6Rrr722pt9ui3BxdTqpD1qU7Y+N7KJsZJjQE692eEX6nzh6lI53dvqeBRs09OTCCy+kjRs3OvnCjlWrzilkPBAXLFgQJWSplpXUQOC51T179\/rOrd7S1ERtbW2xYWKy7JjkeBuX7KJgYuNUTpJSSTbiq7rNDVQ36at7bN9++21SM6vo5GY7hx0VCEnJOKr2cjm5IDtuqFdQsbraunPnTpo7d243jEwLIF5kd83tD9DvNy33PQs2CNnx\/t\/5c+bQomq12\/myDzc2UhLzS1Eqj1tZSQ2EgZddRoerVd8uDWxspDhdWT83VtVPTqip5r4Tz2X8+PFOP9SN\/V7JAdS5bD2vnS8gETyQlIwjaGqtiETJzrRCq2Z1jbJjNmV5kR2TGB9+7XcWrC3Z7Xt6BnWcOOFpLV4f86C0wSSKZ5IaCJdddhm9V61m0rJjHGVRzOZjzB9Cvg4cOFBLAupFdkKMHJHA7ix7Cw8\/\/LCTHTmJKykZR9mXxMjODRw1owOb\/ElefmTndUSi7IqwJbvfrbjXah4w7vmlJPBNaiDYztn9ZeHCWKcJwlh2qjz06Ro\/shNXdsiQIdS7d+9EE+MmJeMo9TURsvMLAmbTXeY0kvoyMYhJkt1zCydaxe4NuvJKZ36JV4bzeiU5ENiVfa1adZ1bTcJaDkJ2+pydLKZxOvZBgwZ5ztmpLi7rhuopuR1zEJcOJSnjqPqQCNl5BfYK6eiCjKqDXuUkSnbzm61j99r276c0Tq6KCvMkB4JfnN1LbW1O8Hncl6RkYneU2+TmxvLHXAiOP\/B8qbkc1XvqSq1u9Ul\/uF6+Jync4+6nlJ+kjKPqUyJkJ5ad6eAO7ojXxv6oOmoqJ0my2zq\/2Tp2jy07kJ295LO2g8K+5eGf5LHD\/TcFzYcv3b0EkJ0HugKOnpGYf5dsq5izI+LYvV27doHs4hypBSlbXclN+uMIslOUKKq9sXHqZZKW3R\/Wzibb2L2k51+ixjiPAyFqDOIuT9xdjmZI2qqTqSe3E9Xi7nu95SfixtbbuLjfS5rsbGP3ikJ2vLOAt+HhKh4C7e3tNGvWLNfzn7PYY5Bdc3MXgQkB+oWUBA09YcvONnYv72RXpBTsWRy0WWlT3tLTJ0Z2fm6tX6r1OASctGVnS6B5JzuWVVFSsMehd0Upk8Oj8hQilRjZqbF0vKVLVpDUOKMsTLLGbdnZBCoXgeyKMqDRj+IgkAjZ6edCSOQ3b4zmuKMyhJ6IGwuyK87gQU\/yhUCiZCeZHtiaW7x4Ma1YsYIaGhqcIEv176QghBubFNKoBwikj0AiZKdvF9OzD4PsvleEsp1Clr76owVlQiARsmNA1dxcbM2p+bfgxoLsyjTo0Nd0EEiM7Lh7am5+dXU2jZVYbg\/c2HSUDrUCgTQQSJTs0uigV50gu6xJBO0BAvEhkCjZ5S15p83KqV\/snDoX5\/cs5uziU3SUDAQSI7uyJ+9E6AkGGxBIF4FEyA7JO9+gesiuzKmL0h0WqL2ICCRCdkjeGZzs+BSyW0eMKPzhPEUcVOhTNhFIhOyQvDMY2ckpZGmnG8+myqJVQKA+BBIhOzXMo6zJO4O4sbfddhuNWLMm9cOf61MpvAUEsolAbGTnl+VEhyONWLushp6cOHHC6nCeuA9\/zqbKolVAoD4EYiO7+pqT7FuZJbujR60O54n78OdkpYHagEC8CIDsEk7eaRO7d\/ToUavDeYpw7GK86o3SgcDfEEiU7PQj5LgZ6nFxXoLh\/bNz5851HrF1ef0OJMmqZXfeVUNp9m+3+M7ZFeFwHgxGIJAUAomRndvpYkJiXgkr9TMzbRIHCNG1tra65snPKtnxTosXVzxI73S0ux7+3L9nT+p38cW5OgMgKaVGPUDAhEAiZOcXVOxFXqZ39RRReseEQPnkpSNHjjinL5myIGeZ7M44pw+9sHAire5opzuJqAcRnSaiZ4nonr4D6KYJM+nNHStBdhjXQMASgUTILkxQseldP\/Lcs2cPDRkyxIFg8uTJvmTHp2CNHj3ayaefhbTssof28452+vPeHXTsrdfoZEc7dRLRj5pup6F33ofcd5YKjseAgCCQCNn5kZOXZedmxan58NzEaUOyfPYlX0x4\/C9LZOelpkgagEEMBIIhkAjZcZPqnbNLguyefPJJ53zTrFl2ILtgyoyngYAXAomRHTeintXYetxY6bCtZacujsCyw4ABAsVEIFGyqwfCehYoykZ2nDRg48aNtHfvXjpWrTpze5MmTaIFCxbUAzneAQKFRCARsvObs\/NDtp7QEy6zDJadJA1YVK12W7V9uLGR1lUq1NTU5Acx7gOBwiOQCNn5kY4Nyl5BxW4LHH71Zjn0xGunBePFCxT7np5BHSdO0PHOTtd4vOsbG+nw++\/bQIxngEChEUiE7GSBgldQ169f75wVm4Ur72T3uxX30lMdHb47LU5WKo5biwsIlBmBRMjOJgOK7RawKIWVd7J7buFEZEeJUiFQVqERSITssopg7slufrNVdpRePXs6riyH1uACAmVFIHayU+faGGSvPbBJCyHvZLd1frNVdpTeZ55JbW1txi1zSWOO+oBAWgjESnZMdKtWraJKpUIDBw6sxdktX748EwMv72RnO2eH7ChpDS\/UmyUEYiM7t3ATm4wlSQGUd7LjVO8njh71XI1FdpSktAn1ZB2B2MjOLexDj5lLE6AikN01tz9Av9+03Do7Co5nTFPjUHeaCIDsMpipWLKeeCmGJALgZzkdlE12FBzPmOZQQ91pIwCyKwDZ2aR6x\/GMaQ811J82AiC7kpAdjmdMe6ih\/rQRANmVhOxwPGPaQw31p41A7GR36NAhqz5iB8X3+11tDtNmQG2fled41fZUJ+dD8b5wPKMfQrifVwRiI7s8AFKE1Vi\/xQwhu6DHM3Z2diJtVB6UGG20RgBkVxI3NsjxjGvWrKH5c+YQ0kZZjyM8mAMEQHYlITvb4xn79uuHtFE5GLhoYnAEQHYlIjub4xn\/Z9NipI0KPo7wRg4QANmViOw4Hs\/veMZ60kZhV0YORjqaSCC7kpGdl87zYsZzAdNG8ULGrSNGYH4PZJJ5BEB2ILuakjLZBUkbtWHDBmch47VqFWnhMz\/U0UCQHciuC9kFSRs1btw4GrFmjXVaeLi7IJw0EQDZgey6kF2QtFFBdmVwTkO4u2kOddQNsgPZdSM727RRtrsy\/o6IGhsbA7m7sAJBTlEjALID2XUjO9u0Uba7Mn5ARNuIArm7tlYgSDFqSihueSA7kJ2R7GzSRtnuyhhLRP9LRD08xtFpIrqlqclJ4c9EZ7PowURnS4rFHcLomS0CIDuQXd1kZ7srgyuwSULAp6DNX7iQBs6f72sF\/mXhQvrVhg1WpGg7GPBcsREoJNnJ+Retra2O9KZOnUqzZ8\/uJskyJQLwSxjA4ATNpCLu7gsLJ3qmhX9x5SzrU9C4HSe\/\/trXCgzqGhd7GKN3NggUkuyWLl3q9J0Jzu3gH74PsuuqIvWQnc2ujCDhLF9\/+aWVFchk952FazzoyiudYyRxZq4NHRT7mcKR3eHDh+mhhx6iZcuWOcc3Cqlt2bKFlixZQr169apJ1JbsvvrqK3rvvffo8ssvp7POOst535YYgjybZJlh+lRPO21PQbNd9DiDiL61GJvsGv90zBgaM2YMDRgwwOINu0eYPOMm0GPHjtHzzz9Po0ePjr0uu16Heyrt\/hSO7Eynl5kIULXspk2bRjfccIMjyfb2dpo1axYN\/OkMOv+KHzu\/MTFwuVdffTVdcMEFzm+nPnyX\/vSrx7o856YKts\/aPhekfrcyw\/SpnnZecOM4+uP21fTLk5\/Rnf9vkfGixLNENLH3uXTThJn03n+tpzMuuoYe27\/Td87OdtGDDwjv169fuFFqeJv1JWoC1asRXVT1M\/KOJFig9Gfz5s2pnBtdSLLTrTg+1nHGjBk0b968mrXHMuYvDRPbq6++2kXknQ1X0LcXDqbTZ5ztqgo9vvmSen7yLvGzXs9xAbbP2j6X1zJ5H+2pD\/5E3370AfU4+Rlx3uQzLxlMZ\/9jUxeMPm1bTydOfua6Ba1f73Op98X\/QGv++oovKd59+T\/T319wEX139vcfKbfrB9985bTB7zl+n5\/94Sfv0A+\/\/DBBqihOVS+\/\/HIqlmqpyU4Ij0kPV3YQYFJsmTDBNblAZdMm6tmzJ00YP953NXbTli3Z6Rha4iAwdOjQVJAoJNnxAsX69eupoaHBAdXNjU0FcVRqhYBNsLBfnN1LbW3Ozg1cQMDxhk6fPs1TJ4W5gixQFKbTJe6IDSmWGB50XUGgcGTHfbMNPYEmAAEgUB4ECkl2tkHF5REzegoEgEAhyQ5iBQJAAAjoCIDsoBNAAAiUAgGQnY+Yi+YS8wJOS0sLHT9+vNZzt73DWR8BIpvx48d3CWfIq8zc+pNHmXFs6+TJk+nQoUOOGuk6loaMQHY+I7poix3btnFmOaKxY3kPQn4vdbDoEfl5lJlXf\/ImMyE6TtvPemban56GjEB2HuO9iGEsrGQ333xzaoGdUdArD\/65c+fSyJEj6ciRI07CBwlUzaPMvPoj0QV5kplpyyb\/JjubOIjfdv96FPoiZYDsPNAMss82SqHEVRZ\/YRctWkRvvfWWq3sRV91Rlrtnzx4aMmSIUyS7SirZ5VFmXv0pisyY0A8cOOAk42DXNo3Af5CdD9nZ7rONcjDHVZabe9G\/f39jvr+42hFVudIfnezyKjNTf4ogM71fqpUnWYjc9q9HpStcDsiuRGRn6mqet9KVgezyLjOREU8zSAJdkF2UFB5RWXl0iYJ2PYkvatA22T7vRnZpuEi2bfZ6ztQf0\/N5kZmJ6Lg\/aY0rWHYlWqBwU7LFixfTihUraokTohi4SZRhIoc8LlAIVkHIO+syk3CZ+++\/v9vKf1oyAtn5jMo0lsjjIgqbkIC46o6jXDdLKK8yCzJnN2zYsMyGD+l6ZpJ9GjIC2fmMwjSCH+MgBt16cAv2jLPuqMt2I7u8ysytP34BulHjGrY8CaXRyxk8eHAt9VoaMgLZhZUs3gcCQCAXCIDsciEmNBIIAIGwCIDswiKI94EAEMgFAiC7XIgJjQQCQCAsAiC7sAjifSAABHKBAMguF2IqXiM59GDt2rW1jvGmfv0Q86R6zauHl156aa6TIySFVZ7rAdnlWXo5bLsEmzK5yfYh7gaTX2trK1UqlS5n+8bdRWnP8uXLQXZxg51y+SC7lAVQpuoltsqUeEDuMR5JWnggu\/JoIMiuPLJOvae8XW3mzJmu1hsHOg8aNIjUTBhqtls1KJU7o6YNknfUOvr06eOkgJoyZQqtW7euW1orfra5ubmGS14zNqcu2Jw0AGSXE0EVoZkmcnLrl8ndZVeXCUoOQLclu46OjhrBCsFJdmNYdkXQLLs+gOzscMJTESDAZMVnX9i4qaZn9T2XtmQn6cG5C7orDbKLQLA5KQJklxNBFaGZtmTnNbenlrFz585a9lsvN1ZN7gmyK4Im1dcHkF19uOGtOhCwdWNv0nkLAAABTElEQVRNB7RIdSC7OoDHKw4CIDsoQmII+C1QyP3Vq1fTM888Q6ZVWzU1kK0bC8suMRFnuiKQXabFU6zGBQk9WblyZbf5PdOc3datW2sLFowWE+CqVaucBQlZjQXZFUuP6u0NyK5e5PBeXQjYBhXbrMa6raxyw0B2dYmn0C+B7Aot3mx2Tk\/cyK00bRfTk1aanlETRXIcHltx7OouW7bMyrLjumXrWppb1rIpqWK1CmRXLHmiN0AACLggALKDagABIFAKBEB2pRAzOgkEgADIDjoABIBAKRAA2ZVCzOgkEAACIDvoABAAAqVAAGRXCjGjk0AACIDsoANAAAiUAgGQXSnEjE4CASAAsoMOAAEgUAoEQHalEDM6CQSAAMgOOgAEgEApEADZlULM6CQQAAIgO+gAEAACpUAAZFcKMaOTQAAIgOygA0AACJQCgf8DkhKWWyEMSXEAAAAASUVORK5CYII=","height":61,"width":101}}
%---
%[output:0015ecf7]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 2.411223\n","truncated":false}}
%---
%[output:853c9768]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAATsAAAC+CAYAAABK1qgYAAAAAXNSR0IArs4c6QAAIABJREFUeF7tXX2MVtWZf2hnDYya4CBRwI9BC9s2bpnFRAjWMJg1+89iVlGBMTSMlFCjSJbvASOoC8IAmzjQKB3JC8XyYSskTLNk14UZ4pYVE2zHxjaVFV9HGGJG1GgFo+Oy+1z3vD1z5px7z33v972\/mxCd9957Pn7Pc373ec55znOGXLp06RLhAgJAAAjkHIEhILucSxjdAwJAwEEAZAdFAAJAoBAIgOwKIWZ0EggAAZAddAAIAIFCIACyK4SY0UkgAARAdtABIAAECoEAyK4QYkYngQAQANlBB4AAECgEAiC7QogZnQQCQABkBx0AAkCgEAiA7AohZnQSCAABkB10AAgAgUIgALIrhJjRSSAABEB20AEgAAQKgQDIrhBiRieBABAA2UEHgAAQKAQCmSK7\/fv3U0tLC40ePZpKpRKNGzeuIiRxb\/r06bRhwwYaNmxYpALcuHEjbd++nRYsWEArVqyItC6\/hQss+D0dVn7LC\/r8Rx99RE8++SStWbOG6urqghaXqve5b\/PmzaPu7m7as2cPTZ48OVD7WHZ8zZw50\/lvmvXMT0e5H1OnTg2Mj5861WczSXbcCZVkQHbfiPbUqVPU3NxMvb29zt8TJkygHTt2JEYyoj0jR45MtB1BBonbu2GSnSC2Z555Jjdkd\/HiRVq5ciV1dHSE8jEIIsfMkh13Wv6SguwGkl1ayCXvZBdk8KnvguzCRHNwWZkmO9llVcnuzJkzjoXDl+zyqm6BrGDlctlxTfkSX1dxX\/5NdS\/4b\/Gezo2Wy1DdSnGP3+vp6XHcITfX+LXXXqOmpqaKJHUYyGJ2K0t2d9X+6T4eOitG\/k3UKz5CaltVi9ytLzLGLAs\/stFZuDIOgoD5ucbGRuejKeQyYsSIiluq9kc3FHWYyDpWX1\/vTL24Wdmy9SPqEO05cOBAZbqE3UAhe53F7qZnurarXoCsmybjQf14cbnCjVfx0umG3G5V\/3TGC8tNxlDIUX7Xdiopk2THgPX19TmumiCloGSnKgMLnq0jJh\/5EgKRFUt9VxAQ\/y5MePUZt3JkN0Z+T1UOcU8o0CuvvFIZWOKeSRFM7TfhyXOg6sAeP378IEWXFZ7\/XyZmmey8+sJze6Y2eslGR7Jct5CL+BAKV18Q0aZNm2jZsmWDZM73TfNxbmSnIxjdx9CG7NzKstEz9X2V6FSSFaTP40w2FoTcWK\/mz5\/vKn+dfghdbW9vrxgIcttU\/dP1+4477qBXX311wC3TmJEfyiTZscI0NDTQ008\/XZmTEgNdVWjurI1lJ4Qgf6l0v6kWn\/w1lAcZDw4x2GUFF8+I39ra2hyhey0kyMop2iAPEkFqNm6jXJZqhanEKbddHdg8INh6ll1m1XLWtce2L6IsP7K5++67B80RqfNGot1MdjqLz60\/6uBzIzudpeQmZzc3Vqdn4rfz5887HxU3PVMX7FQ9lAlT1XFV306ePOmMKb685K+bs3PTCYG9GM+ij9ddd11FrrrfbKy7zJIdr+zxCh9PfMqmbrVkJ4OlWwFTFVH3jCxY1fVSB4n6hfMSlsmtEEorymPFVxVQrVtVdN3KtY0bq365da6VTrFt+yK+\/n5kM3HixAELNGrfWS7iGfVDqLpdNos7Xm6sWKmXXWc1kkC00XbOTi1LuLo6K8jUB9Wy01mcqp4Ii\/jWW291Ih5Y32UXVleXjuxMVj23XxDZG2+84XgpblNVrLeypekVFZFZsmOw2cXkLxoDJOZeqiU73QqY2286xWRhmeYAVUXUzcm4CcskVJVMbMjOZjHHhuw4zMLkMgrs3MhOJXj1WUF2fmTjRXZc57333qudz2UZefXHj2VnmieMk+zcLEkT6QhrXxC5cGUFqcry8MLLL9mJKYP33nvPITsZQ90YKAzZMbOr8zpxk50sDJNl52a12cZR2VpDNmQXlmWnxpTJ1oKbpWnblyBkp1ptMknZWFn8vK4\/apxgmiw7L+9AZ\/mJ32TSkq0poZ+LFy+mI0eOOHPlJrLW4cVjVA098fOxBdlJgcMmc1yehBZfKvlZAaKb62Bj2dnMpbitcok5Oy9FtZ3nqnbOTiUA4UaYVs\/kOUn5GbUcMa8jk49tX6qRjTxnJzA1zTWqhKhOCTCxeRFjFGTn5barbRJzdjarqYLcdISj679quclts8FLnmtTrX2eM\/WaMwbZKbskZHPcZiWUBR4W2em+ljZtUFdjvchOdpFN83\/y4PSKszOtdKoLHfKKpVwvt59JzrTabFr5VBdm3PpSDdnxzgPb1ViV7HSroqJ9pp05UZCdqJMxPnbs2KCdOirZyYSi4mmziqy+Y\/JWhIspLHobvPgdWUfU6RvdnCrL0NZlLZQby2DJCmdaPRQEx\/+Vt3lVO6Bk91OUyf9VB4VOIWQFtHVjde6Grj4by079uou\/VcJVSWPbtm3ErqW8NUrXP7Uc3ceI3Rs\/cXbq9imveTy3st2sNZv+yAM0TLJTF0hsyY63TXrpme6jrIuD04VwCPl5LUCY9Ei25GXrU\/3gynUXmuzkAeO1SqYK3iYGx20+A\/eAQJER8PtBTitWmViN5a80Ay72eDLxHT9+XLvhXxAdf0F4dVN8vfj\/g27STqsQ0S4gEDYCqsHgFQcadv1RlJd6shOgT5kypbI5mglsyZIltGrVqgGZTxggNpmXL19Ora2tlXtMlHx5xeFEATDKBAJZRUB2M8PI6JI0DqknO51lpiNAE5Cw7JJWMdQPBNKBQCbITmfF8VeHNwiLiWsVTt1WKh3kHKLC\/3hFi\/\/hAgJAIJ8I5JbsZHGZ5viY5Hjj94kTJ2jRokXOP1xAAAjkE4FMkB3vv5MXGPy4saZ5PP5dhCdwtotJkybBssunjqNXQMBBIPVk53eBQl25tSG7PEy+Qp+BABBwRyD1ZCcsML+hJ2L1Vg1FkeEQlh3IDsMECOQfgUyQHYvBLahYnZNTI8NNW7FAdvlXcPQQCAgEMkN2UYgMZBcFqigTCKQTAZBdU1PgU4\/4fIRdu3ZRV1cXnSmXqZ+I5s6d6xwdiAsIAIF0IACyC0h2THR3TZtG68plup9XfIjoEhH9kohW19dTe6nkJBbFBQSAQLIIgOwCkJ0gutfLZbpKI8ePiei2+no69e67yUoZtQMBIJD+0JMoZRR0zm7nzp1U29xMD7g08iUiulAqOW4tLiAABJJDAJZdAMtu2rRpdLSry3FdTRe7tHc2NlJnZ2dyUkbNQAAIwLLjA3uqibPjrWbjxo6li\/28HOF+DaupcVxZ7L31Qgr3gUB0CMCyq5Ls2AXmw3q\/7O\/3tOxqhw51LDvk04tOkVEyEPBCAGQXgOz4cJdtfX2ec3YLhg+nw4cPF4rsRDYZLwXE\/ewikLVMQSC7AGTHLvC599+n3v5+42rs6JoaGnX99VW5ylkdBnI2maz2Ae32RoCTZ3ASjaxMz4DsApLd39zzGP3n7s30XN\/ZQXF2D48cQz+cs5R+f7CtUGQnZ5MZM2aM96jBE5lDgNOiPfvss5nSa5BdQLK7fcFGuuzKEfSHroN05q3X6ULfWWcHxfcb76HJ9z9KH55+k36zfUWmlCLoyAsa0hO0frwfPQJZlDHILgSyu\/qmHxi1C2Q3uYJNXubxsjZXFQX1gewMqMpZSNJ0rGEQgYl32bID2Q0UvA5XJrofP\/JP9PbvT0Yx9mItM2tzVVGAE2TsRNEemzJjtezkNE3cuKSJL4jAQHZm9dLhKn772wcWU+1V19joZiqf+fCdN+lP\/\/EL62mJsE+2052eZwNU2O0IMnZs2hvFM7GSndyBNBBfEIGB7KojOy9LOAolD7NMv9MSYZOMLdmpz4XdjiBjJ0x5+CkrMbITjVRJb8KECZXDsP10pJpngwgMZAeySyJIvFqyq2Z8uL0TZOyE3Rbb8mInO7eTxsU9bjwva0d9BREYyA5kJ5OdfKD09OnTacOGDTRs2DASFtVjjz1GK1eudA5uP3LkCHV3dxM\/99BDD9EjjzxCvb29zt\/8Ht+TjyGQCY5Rlw+BF3oopMFTQ3fddRfxIVVczujRo6lUKtGBAwecR8RB8XJ7RSZvMf6uvPJKJzcjt8lkfAQZO1GPa1P5sZCdmiadG2PajyoOzDl48GDkmAQRGMgOZCfIjnVh7969AwhOnGmskl1PT4\/jufDFhHTDDTc47\/ECTnNzM23evNm5Z0N2I0aMIPlMZTF2uPzz588PIEXZjZWPMWCC43bMmjWLeEcQE7JoI5M1\/82EKUhSSD3I2Il8YBsqiJXsGFDTodZJABBEYCA7kJ1MdqaEEirZqQdBib+FQSBbXkxadXV15GbZyVJgEtu3b59DpiayExamqJffF+T3xBNP0FNPPUXyPdNcX5Cxk8RY5zpjIzv5C6R2Vv4isXDjuoIIDGQHspPdWNWdFJ5LlGTH8X5seXV0dDjC4MQUn376qSvZzZ8\/37Hk5HOYQXYhMg5\/tdzITv4igexCBD6hotxCT4qwGivrc3t7uyMF1aJSz0OuxrJj6012d23cWFh2EQ0KeRLUq4okYu5g2XlJpbr7RSM79ShPeQ6vra3NN9nxXJyYv2PrkcvfunWrs9DAl1igYLJbunSp87uw8sR8W5A5O7ix1em985aXZReg6ECvguwCwWd82Y3s\/vrvHqSrbzZvr4umReGVeuHjD+i3L\/3LoAU2+cMuVkB55bUaN5YJTi5v8eLFdPLkSVq1atUAspPdWK6T77Ml2draWiE\/dnHZpT527Jjzrs1qLMguPH1JTUkgu2hEocM1T2mfsF2MKMjYiUbrvEuNbIFCzEHwCqwc92NqklcwsRx87PWsGuoi4ojUur0E5nYeLBYozMplwhWJALwHZFae8Bo7aexHZGQXZmfV1Vp1jkSuSyZZDnNRJ4LlZ90E5nUe7I9\/8hPavn07eU24+91eFCZuSZWVxYGQFFZZrTeLMk492enIym0OUBfGogZ9CgUzCcz2PNivhwwB2WlGaxYHQlZJJ6l2Z1HGqSc7eUlexDW5WWs64ZssQdPc0sMPP0xzfv1rz7MlHh05kv5+yU+R4kkBPYsDISnSyGq9WZRxZGSn2yLmJljTPJzJiuPVKrElx61cHVmqlt2iRYtoxowZzgoWC5HPg73wxRdWp4bdt\/bnILuEyc5tbjUJMgk7w0gSffCqE2TnhVAV94OQnSA6tgjVvX3cFDnqnQmP\/zlkd8cd1ufB3vfPe0B2CZKd19xqe6lEjY2NVWie\/SvqBxVkZ49dnE9GZtmF1Ylq3VgvopPJjk9I4nACYdn5OQ8Wlt1gScf11bedW+UDyqO8QHZ\/Sb0fJc5By46M7MIKPfG7QMGA8MZpjkBfuHCha+IBU\/Crn\/Ng\/2Hlz2DZJWTZ7dy5k2qbmz3nVi+USjR37tygY8X4PnsEYn+qCOD97LPPiP\/x73KQsayfnELJ9h7rKq\/+i\/dvv\/12mjhxYkW\/TYtwUXU6rg9amO2PjOzCbGSQ0BO3drhF+tueB+sn9OTaa6+lXbt2ObnCzpTLzilkPAjXrFkTJlyJlxXXQOC51aNdXZ5zq3c2NlJnZ2dkuOgsOyY53sYldlEwsXEqJ5FSSWzEl3WbGyhv0pf32L799tskZ1ZRyc12DjssEOKScVjt5XIyQXbcULegYnm19dChQ9TS0jIII90CiBvZ2Z4Ha0t2vPf38ZUraV25POh82dX19RTH3FKYiuP3IxJF3ePGjqVT5bJn0ePq6ylKV9bLjZX1kxNqyrnvhOcye\/Zspx\/yxn635ADyXLaa184TkBAeANl5gKhboZWzuoYgA19FuJGd7XmwNmR37KdLqO\/cOert76erNC38mIhui3hA+gIm4MNxDYSxY8fS6XI5lZYdQygWxWw+xvwx5Ov48eOVJKBuZCeIkSMS2J1lj2H16tVOduQ4rrhkHGZfYrPsTODIGR3Y5I\/z8iI7myMSbcju37Y8Qtv6+hKfW4oL27gGgu2c3R\/Xro10qiCIZSfLRJ2u8SI74co2NDRQbW1trIlx45JxmDobC9l5BQGz6S7mNOL6MjGIcZHdr9b+yCpub\/x3vuPMLfGqcJavOAcCu7Kvl8uJWsx+yE6dsxOLaZyOffz48a5zdrKLy\/ohe0qmYw6i0qM4ZRxWH2IhO7fAXkE6qiDD6qBbObGR3eNN1nF7na++SkmcWhUm3nEOBK84u1c6O53g86gvkZKJ3VFuk8mN5Y+5IDj+wPMl53KU78krtarVJ\/rD9fI9kcI96n6K8uOUcVh9ioXshGWnO7iDO+K2sT+sjurKiYvs9j3eRF\/293vOLdUOHepYdiA7f1JP2w4Kf60P9jSPHe6\/Lmg+WMnub4PsXPAR4KgZifl3kW216HN2C4YPp8OHD4PsohylOSpbXsmN+wMJspMUKay9sVHqZlyW3W+2ryDbuL24516iwDeLAyEKHKIsU7i7HM0Qt1Unpp5MJ6pF2e8gZcfixgZpYJTvxkl2tnF7eSI73lnA2\/Bw5Q+Bs2fP0rJly4znP6exxyC7pqYBAhMEaBNSwhabn+cuu3IE\/aHrIJ1563W60HfW2UHx\/cZ7aPL9j1KeknzmKQV7GgdtWtqUtfT0sZGdl1vrlWo9CgHHadnZkmIeLDuWVV5SsEehd3kpk0OkshQmFRvZybF0vKVLrCDJcUZpmGSN0rKzCVLOC9nlZUCjH\/lBIBayU8+FUDcx5z30xI+7C7LLz+BCT9KFQKxkJzI9sDW3fv162rJlC9XV1TlBlvLfcUEENzYupFEPEEgegVjITt0upmYfBtlRrhYokldrtAAIDEYgFrLjauXcXGzNyfm34MaC7DA4gUDUCMRGdtwROTe\/vDqbxEostwdubNTqhfKBQHoQiJXs0tPtb1oCskubRNAeIBAdArGSXdaSd9qEitjGz9k+h9XY6JQdJRcbgdjIrsjJOxF6UuxBht6nA4FYyK7oyTv9kl1RDuZJxxBAK4qCQCxkV\/TknX7IrkgH8xRlkKGf6UAgFrIrevJOW7Ir2sE86RgCaEVREIiF7OSVzyIm77Qlu6IdzFOUQYZ+pgOByMjOK8uJ2v0kYu3SFnpiezBP1Ic+p0M10QogEC4CkZFduM2MprTUkZ3lwTxRH\/ocDdooFQgkiwDILsbknV5xe7YH8+TlyMVkVR+1Fw2BWMlOPUKOwZaPi3MDn\/fPtrS0OI\/YurxeB5KkzbKznbPLy8E8RRts6G+yCMRGdqbTxQSJue0cUM\/MtEkcIIiuo6PDmCc\/bWRXtIN5klV91F40BGIhO6+gYjfy0r2rpohShSYIlE9e6unpcU5f0mVBTiPZFelgnqINNvQ3WQRiIbsgQcW6d73I8+jRo9TQ0OAgO2\/ePE+y41OwZsyY4eTTTzotO++hLcrBPMmqPmovGgKxkJ0XOblZdiYrTs6HZxKaDcny2Zd8MeHxvzSQnddCBru7SBhQtKGK\/gZFIBay40ZWO2cXB9lt2rTJOd80LZYdyC6oWuN9IDAYgdjIjquuZjW2GjdWdNPWspOtJFh2GCZAIJ8IxEp21UBYzQJFUcgO2VGq0Si8U1QEYiE7rzk7L\/CrCT3hMvNs2SE7ipfW4D4QGIhALGTnRTo2QnELKjYtcHjVm8bQE5uMxsiOYqMxeAYIJEB2YoGCV1B37NjhnBWbhiurZGe70+JCqURz585NA9RoAxBIHIFYLbvu7m5jh223gIWJWFbJDtlRwtQClFUUBGIhu7SCmVmys8yOMqymhk69+64TUoMLCBQdgcjJTp5rY7DTFAybVbKzzY5SO3QodXZ2arfKFV3x0f\/iIRAp2THRbd26lUqlEo0bN64SZ7d58+ZUDMCskp3tnB2yoxRvQKPHZgQiIztTuIlNxpK4BJZVskN2lLg0BPXkCYHIyM4U9qHGzCUJZpbJzk92FAQfJ6llqDstCIDsUpSp2PZgHvGcTXYUBB+nZaihHUkjALLLMNl5JQxA8HHSwwv1pwkBkF2Oyc52IQPBx2kakmhLVAiA7HJMdgg+jmrYoNwsIhA52bntmpABww6KN8nvnJ2XG\/sry+BjHM2YxaGLNvtFIDKy89uQJJ7P8mqsTcIA2+BjcTRjf38\/7dq1i7q6uuhMuUz9RM7e2jVr1iQhHtQJBEJFAGSXYzfWds6Og4+ff\/55enzlSlpXLtP9RDSEiC4R0S+JaHV9PbWXStTY2Biq8qEwIBAnAiC7HJOdbfDxyFGjqO\/cOert76erNNr3MRHdVl\/v7LPFBQSyigDILudkZxN8\/F+719O2vj56wEWLXyIirNpmdZij3YwAyC7nZGdzNKPfVdtyuYy5PfBH5hAA2RWA7MJateWUUa90dlLznDmY28vcUEeDQXYgO7Jdtb2spoZqiDC3B97IJAIgO5Ad2a7aPlhTQ7\/o77ee24O7m0lOyG2jQXYgOyeY+dz777tabKNraohqaujCF184YSmmi8NV7mxsdHIY3jVtGtzd3FJH9joGsgPZOWRns2r7723L6GI\/hxq7X39FRPX19fR6uWwVygIL0AtR3A8DAZAdyK6yTc0rZZTt3N63iGg\/kZW7y4HKthYgSDGMIV\/cMkB2IDvrPbm2c3szieh\/\/n8Xhpu7e1N9vbPgYWMBMtHZkmJxhzN67oYAyA5kZ0121nN7RFbuLhPdHgsL8I9r19KLO3dakSKGOxAwIZBLshPnX3R0dDj9XrBgAa1YsWIQBnlPBBB2FhXbub1\/bVtGX\/b3ey5ksLtrYwH6cYtxKDjIrlBkt3HjRqe\/THCmg3\/4PsiO6MPT\/lNLec3t2bq7D\/5fkoGvLMYmk93XFm4xrwLz0ZG4gIAOgdxZdqdOnaLly5dTa2urc3yjILW9e\/fShg0baNiwYRUcbMnu888\/p9OnT9NNN91El19+ufN+NSThtZMhCktMTgUVZz9sQll4XdfGArzMkhR5h8eL+\/bRmDFjQhntfLh4lAeMnzlzhl5++WWaMWNGpPWEAoZLIVnpR+7ITnd6mY4AZctu0aJFNGnSJEecZ8+epWXLltG4f1xCV9\/8A+c3Jgku95ZbbqFrrrnG+e3iB+\/Q7158asBzOn1I03Nx9uOa22fRbw88Rz+\/8MmglFE\/qh1OP5yzlN488KxVAgLbBQ8+FHzUqFGhjW3Wifvuuy808lQbJnRN1r\/QGh9jQX77MXny5Bhb95eqckl2qhXHxzouWbKEVq1aVbH2GAL+IjGxnThxYgD4X107gfrrbqZLl11hFMqQL\/9MNR+9g+cUhGRcOBnoxfd+R199+B4NufCJkwx06A0T6IrvNZJ4rq+7i85d+MQYjzeqdjjVXv9dev5Pr3mGssy\/7rt0+femug6kb335uVP311d889EyXfzctz\/6b\/r2nz9IZGDmuVL2kpK4Ck12gvCY9HAlgwAToltigdLu3VRTU0NzZs\/2XI3dvXdvMp1Arb4QgGXnCy7zw37c2JCqRDEBEbAJFvaKs+NsLLxrAxcQMCGQO8vOzwIF1CJbCNiQYrZ6hNbGiUDuyI7Bsw09iRNo1AUEgECyCOSS7GyDipOFHrUDASAQJwK5JLs4AURdQAAIZAMBkF025IRWAgEgEBABkJ0LgHlxh3nRprm5mXp7eyu9Ne0XDqhPkb0uZDF79mySQxeyJiNTP7IiI45ZnTdvHnV3dzuyVvUozfIA2bkMz7wsdOzfz9nliGbO5L0I2bvkAbRnz54BZJclGbn1IwsyEkQ3a9YsR5d0+87TLA+QnWHs5ymEhRVw6tSpA0giK5THJNDS0kLTp0+nnp4eJ7mDsOyyJCO3frAssiAjXQwr\/yZ2LHFwvu2+9CT0D2RnQD0vwcn89V23bh299dZbRtcjCcWzrfPo0aPU0NDgPM7uk0x2WZKRWz+yLCMm8ePHjztJNti1ZdLesWMH1dXVOTIz7Uu3lX+Yz4HsXMjOdo9tmAIJuyyT6zF69Ghtjr+w6w+rPNEPleyyJiNdP7IqI7UvspUnsguZ9qWHpRd+ygHZ5ZzsdN1L09fWVlnzTHZZlJGQB08piMS4IDtbbU7Zc1lykfxCl6avrW3bTWSXZrdJ1zddP0zP6TL12OIV5XM6ouP60j5mYNkZtCJLk99uim1SwPXr19OWLVsqcytRDo4wytaRRBZl5Ie00ygjESKzcOHCQav7aZcHyM5lJKZ5Gd2WQGzCBWzLSvI5k0WUNRn5mbObMmVKqsKFVF3S6UOa5QGycxnBaQ6Q9EM8XoGgfspK6lkT2WVNRqZ+ZEFGInxG1YEJEyZUVmDTLA+QXVKjF\/UCASAQKwIgu1jhRmVAAAgkhQDILinkUS8QAAKxIgCyixVuVAYEgEBSCIDskkIe9QIBIBArAiC7WOFGZQIBDlHYvn17BRDe6K8eYh4XWrzKeOONN2YyUUJcGOWhHpBdHqSYoT6IoFQmN7HNiJvP5NfR0UGlUmnA2b5Rd020Z\/PmzSC7qMFOuHyQXcICKFL1IgZLl4RA3GM84rTwQHbF0UCQXXFknXhPeeva0qVLjdYbpwgaP348yRkz5Ky4cvAqd0ZOLyTekesYMWKEkxZq\/vz51N7ePijFFT\/b1NRUwSVr2ZsTF2jGGgCyy5jAstxcHTmZ+qNzd9nVZYIS+dJsya6vr69CsILgRMZjWHZZ1ih\/bQfZ+cMLTwdAgMmKz8GwcVN1z6p7M23JTqQR56arrjTILoBAM\/YqyC5jAstyc23Jzm1uTy7j0KFDlSy5bm6snPATZJdlDQrWdpBdMPzwtg8EbN1Y3UEuohqQnQ\/A8egABEB2UIjYEPBaoBD3n3vuOXrhhRdIt2orpxCydWNh2cUm4lRXBLJLtXjy1Tg\/oSdtbW2D5vd0c3b79u0bcMALE+DWrVudBQmxGguyy5ceVdsbkF21yOG9qhCwDSq2WY01raxyw0B2VYkn1y+B7HIt3nR2Tk3wyK3UbRdTE1rqnpETSnIcHltx7Oq2trZaWXZct9i6luSWtXRKKl+tAtnlS57oDRAAAgYEQHZQDSAABAqBAMiuEGJGJ4EAEACsJrblAAAAgklEQVTZQQeAABAoBAIgu0KIGZ0EAkAAZAcdAAJAoBAIgOwKIWZ0EggAAZAddAAIAIFCIACyK4SY0UkgAARAdtABIAAECoEAyK4QYkYngQAQANlBB4AAECgEAiC7QogZnQQCQABkBx0AAkCgEAiA7AohZnQSCAABkB10AAgAgUIg8L8mMEdb0QrcUgAAAABJRU5ErkJggg==","height":61,"width":101}}
%---
%[output:67d64d7d]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.060537\n","truncated":false}}
%---
%[output:0d80950b]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAATsAAAC+CAYAAABK1qgYAAAAAXNSR0IArs4c6QAAE4VJREFUeF7tnU9oHccZwMdH9SgIBdkEXdScit34YKESckh81MUOleIcUqEEE7BjqGIrkiHBCYmVWHGxhQ+CKsKHWHJBBKxjQiCEihgSF\/UWDEUYRVBS+1gfVb4t87oa7Z+3T7s7u\/P9HphE0nvzzfy+2d+bmd2dPbS7u7treEEAAhAInMAhZBd4hmkeBCAQEUB2dAQIQEAFAWSnIs00EgIQQHb0AQhAQAUBZKcizTQSAhBAdvQBCEBABQFkpyLNNBICEEB29AEIQEAFAWSnIs00EgIQQHb0AQhAQAUBZKcizTQSAhBAdvQBCEBABQFkpyLNNBICEEB29AEIQEAFAWSnIs00EgIQQHb0AQhAQAUBZNeSNH\/yySdmcXExs7ajo6NmfX3dnD171kxPT9fasrt375qZmRkjdZibmzN9fX09x3\/y5Im5cuWKef\/9901\/f795+PChmZiYiMpbXl42Q0NDPZft84PSjtu3b5vLly8fiI\/PNrQ5NrJrSfa0yM6K7ZlnnjFLS0vByO777783Z86cKeXLoCVdtnHVRHaNS0l+heyBc\/To0Y4Q8j\/Vjncgu3bkqY21RHYtzFqa7Ozoz05j7dRSfh4cHIymmfJy\/x7\/ncUhU8nJyUmzubkZ\/SpveupOY7e3tztTz\/n5eSN1s2VdvXrVjI2N7SNv2xX\/g9T11KlTnbJu3bplPv\/882i6Li+3LCvLnZ2dPW3NSrM7arZ84gzu3LljhoeHO8XYz9j4tv32DXFe7t\/i9c7jHI+ztbXVWcqwceN1T+Pawi5eSZWRXSVYqy20qOySavPCCy+Y7777bs+f7MHiCsO+KWskmSY7Kx23Dq485O95sssrK+nzeaJOWx5I+sKw66BWUL\/88ku0hvjgwYPOF0m8nVZ49+7d2\/d3Yf38889HEnfbFeecVr+BgQEjU337BWLjJnGttje2p3Rk155cdWpaVHZyYMhBeeTIEfPuu+9Go6Kk39kD3B21SOCk38XRZckuaaSUdhIlaxorUrCfe\/r0aact8ru3336787M94OPvSZJA0t9dto8fP46EFF9DtO9J45V0QiVpza4bzvY9VoDC3I64k37H6C79gEZ2CmSXNKVK+p0cvG+++eae6auLJ01SWdPY+BlUd6rtll9kzS5elp3qpo3+0iTgjpxcKSYJ0X7GvtedpibFcmUn5caXCdI4J\/HK+h2yQ3YtVFp6lYuO7OKCiq\/j2WlZ\/Hd5sktbu2u67NIk7a6ZZa25xdcP4yO9uBDjWYtPR4vKznK+efNmtE4Xl1g3I8KgOnxJjWFkVxLIOoupS3ZF1n+aIjvJQ6\/X4rnSsu2PjzZfeuklc\/369cxrGZNOGmTJLotzt2LLW2aos382NRaya2pmMupVpexktGcPHDu6kKrYtb60aVLZsotLK+2i4vh0Lr5m183ZVCk\/6WxrXHi2ra4E7XqnXNyc9P74GqetS1LOuuGM7Mo7QJFdeSxrK6lq2ZV5NtYdaXW7ZmfX3kS4b7zxhnnrrbcivlnrf72cjU26LETixIUmP8fLdqfyaXHlc3bU5r4nPiXu5mws09iDH17I7uAMay+hatlJg1zh5V3AXNbITmLHBVREdq6U5Oe86wPdePJzUlvjo8CsExC2M7iyjI\/25P\/tiC+PMyO78g6v1sgufgDkHXjuorOPe0XLSxElNYFAKPfnNoGlrzq0QnYykpFvOHuvpIhvY2Mj8YZzK7rx8fHoKn27pjIyMpJ41b4v8MRtB4Gk6Wfdmyy0g1Tza9l42SXJSoQ2NTVlZmdn9+2A4YrRTm1WVlYOvBtH89NJDcsmEJ9mdjMlLjs+5ZVHoPGysyM1+Ta19yYWHa1ljQTLQ0lJEIBAkwm0QnZJoziZ1srN7Uk3lMeBJ8ky\/ne5YV3+8YIABKonILcsyj8fr6BlZ0UnI8KkdZasSwZ8JIOYEAidwIkTJ8y1a9e8CK8VspN7CItOY\/NEZ9fyZEPFZ4+fNI9+\/CpKwuHDh4Pob\/fv3zc3btwIqk02MbStnV3U5q3InTlltrTxsit6gkLg2EXl8+fPZ05z7cjuuZdfMz99\/UXnAtAyAfsqS6bma2tr5vTp016+RatsN22rkm51ZdvjDdllMD7IpSdZqQtZdtV1WUqGQG8EkF2X3LIuKo6fbU3aKFFCJF2I7MruwoULQY6EukTM2yBQKQFkVyne7MJd2cm7fS6gekRBaAhUTgDZVY44PYArO3uiwteagkcUhIZA5QSQXeWIu5ddiCcqPOIlNAT2EEB2HjuEO7JDdh6TQejgCSA7jylGdh7hE1odAWTnMeXIziN8QqsjgOw8phzZeYRPaHUEkJ3HlCM7j\/AJrY4AsvOYcmTnET6h1RFAdh5Tjuw8wie0OgLIzmPKkZ1H+IRWRwDZeUw5svMIn9DqCCA7jylHdh7hE1odARWyy3vmpq+sIztf5ImrkYAK2dnEuk9fT3rYcJ2dANnVSZtY2gmokl082U0QH7LTfvjR\/joJqJVd2mgvaZPNqhKC7KoiS7kQ2E9AnezsMyXW19cjGgMDA2Z5eTl62LX9m\/xeHhZT9QvZVU2Y8iHwfwIqZBc\/QWGbnrZBpgCRZ8J++eWXlfcTZFc5YgJAoENAlezGx8dzH2pdZ99AdnXSJpZ2AmpkNzU1ZWZnZ6Ppqvuyo7mlpSXT399fW59AdrWhJhAEDLIzxsiZ2dXVVYPsOCIgEC6BoGUna2+Li4tdZc\/HNXeM7LpKDW+CQCkEgpadJSQnKLKmsaWQ7KEQZNcDND4CgR4JqJBdj2wq\/xiyqxwxASAQ\/tlYe7mJnIE9efKkmZycNJubm6mpr\/NiYlsJZMeRCIH6CDCyq4\/1vkjIziN8QqsjgOw8phzZeYRPaHUEkJ3HlCM7j\/AJrY5AsLJLukUsK7us2anr+zRYGYFgZdeGPDKya0OWqGMoBJCdx0wiO4\/wCa2OQLCy49ITdX2ZBkMgk0CwsmtD3hnZtSFL1DEUAsjOYyaRnUf4hFZHQJXsks7Qjo6Omrm5OdPX11d78pFd7cgJqJiAGtmlNVS2d1pYWOhszV5nX0B2ddImlnYCKmRnny0xMjKSuFOxbAW1s7NT+wgP2Wk\/\/Gh\/nQRUyM5OX6enp83w8PA+vgJBhMfmnXV2PWJBoF4CKmRnR3byJDERnvuSqezGxgYju3r7HtEgUCsBFbITorah7o7E8vt33nmHNbtaux3BIFA\/gWBlx72x9XcmIkKgyQSClV2Todu6cYKiDVmijqEQQHZdZlLW9WZmZqJ3d7tDil0rfPXVV1NPjJw5c8Y89\/Jr5qevv+j8N+0B3l1WlbdBAAIJBNTILm9amyUw92xtNyc0rOjW19dNmrwY2XFMQqA+AmpkF7+W7t69e2Zrays6M\/vw4UMzMTFh5ufnE0dfSdfo5T2tzI4C5e6MR48eRXHSLnlhZFdfZyeSbgIqZBffAWVsbCw6M7uystK51CRrpJZ0jV7eRcrffPONOXbsWNSz5EE\/yE73QUbrm0FAleysdGQ09\/HHH5vPPvvM9Pf3R6O7+M\/x1KSN4mSkODg4mHhHhv18Nxczy8ju2eMnzaMfv2LNrhnHBLUIkMD29ra5f\/++uXjxYuqyUtXNPrS7u7tbdRB3JOYKzLfsbPvtiQpOUFTdIyhfG4EbN24Y+ScvX8dXLbKTBspUdXV1tXNLWHxkVvY0lpGdtkOJ9jadgIzs1tbWIuEFLztJhghOXjKdjZ+dzToT28sJiqKy49KTph8q1C8EAirW7A6aqF4uPZGY3a7ZIbuDZojPQyCfgCrZHWTzzqyLitOmwcguvwPyDgjURUCN7Ni8s64uRRwINJOACtnlXRfH5p3N7JzUCgJlElAhu26mk2zeWWa3oiwINI+ACtmxeWfzOh41gkDdBFTITqCyeWfdXYt4EGgWgWBll7fLiZuGbrdtKjN97HpSJk3KgkA2gWBl14bEI7s2ZIk6hkIA2XnMJLLzCJ\/Q6giokp3du06eEWtf8sSx5eVlMzQ0VHvykV3tyAmomIAa2aWdoLB3Rvi4ORjZKT7yaHrtBFTILu+i4m62Wa8iM8iuCqqUCYFkAipkx0XFdH8IQECF7BjZ0dEhAAEVspM0s2ZHZ4eAbgJqZCdp5mys7s5O63UTUCW7pqWaExRNywj1CZmACtnlrdn5SjCy80WeuBoJqJBd3tlYX4lHdr7IE1cjARWysycofOxZl9WpkJ3GQ442+yKgQnbd7IDCrie+uiBxIVAPARWyqwdl8SiM7Ioz4xMQ6JVA8LKLPxVMIPm4BzYtOciu127L5yBQnEDQshPRLSwsdHY1sdfZzc\/Pm+Hh4eK0Sv4EsisZKMVBIINAsLJLu9zE103\/STlAdhybEKiPQLCyS7vcRBrclLOyabK7cOGCOX36tDly5Eh9PYFIEAicALLzmOA02UmVfvPb4+Yvt\/6M8Dzmh9BhEUB2HvOZJrtnj580j378qlEnUzxiIjQESiGA7ErB2FshabJ77uXXzE9ff4HsesPKpyCQSADZeewYyM4jfEKrIxC87DY3N7tKapPuoGBk11XKeBMEChEIVnaFKHh6MyM7T+AJq5IAsvOYdmTnET6h1RFAdh5Tjuw8wie0OgLIzmPKkZ1H+IRWRwDZeUw5svMIn9DqCCA7jylHdh7hE1odAWTnMeXIziN8QqsjgOw8phzZeYRPaHUEkJ3HlCM7j\/AJrY4AsvOYcmTnET6h1RFAdh5Tjuw8wie0OgLIzmPKkZ1H+IRWRwDZeUx5nuxkx+ITJ05EG3iya7HHRBE6CALIroI02udfrK+vR6WfPXvWTE9P74uUJzv7ARHetWvXEF4FuaJIPQSQXQW5lmdcyEsEl\/bgH\/l7nux+94c\/mf88+RcbeVaQI4rURwDZlZxzeVzjpUuXzKeffmqGhoai0gXyysqKmZubM319fZ2IebL7\/dn\/SfNvi9OmbQ\/h2d7eNmtra0E+OIi2lXzQ1FQcsisZtAB1n16WJMD4yM4+c8L9r2zi+av+X5u\/\/\/V6VEuZzr7yyivm8OHDJde6\/OJ+\/vlnc\/HixUjSUu+QXrStndm0ebtz546X50Yf2t3d3W0nuuRaJ43i5LGOU1NTZnZ2tjPak0\/LCOHUH8+Zf\/\/zHyEhoC0QaCwBn+vfqmVnhSfS4wUBCFRPwOeVDUHKrttpbPWpJQIEINAUAsHJrsgJiqYkgXpAAALVEwhOdoKs20tPqsdLBAhAoCkEgpRdtxcVNyUJ1AMCEKieQJCyqx4bESAAgbYRQHZtyxj1hQAEeiKgUnYhT3PlmsLJyUmzubkZdYi0+4J76i0N+1DSBeQNq2Kh6rj98ujRo2Zpacn09\/cXKqeJb25Cv1Qpu1BPYNgONT4+bsbGxjLvC27iAVGkTrat8plQhCD9cmdnp3Nb4927d83Gxsa+2xyLcGrCe63EBwYGcu9Xr7K+6mQX8qUpSSOdtPuCq+xUdZRtv7CkfSHILu2WxjpYVh3DfjHJxhzDw8NROBH51tZW4m5EVdVHneyK3DtbFfQ6yw1ldBBnJjn89ttvzYsvvrjvPug62ZYZK8Q8WT6M7MrsKQXKKnLvbIFiG\/nWpG\/URla0QKXkwPnoo4\/M66+\/bh4\/fhyU7GSkMzg4aGZmZiIio6OjrZ\/CxlMro\/HFxcXoVz42A1A5snO3e0rbKKDAMdi4t1rRybQhaePSxlW4ywrJCEhesiYZ0gkKaZdI7urVq1Hb5OWu4XWJqHFvS1tLtmt4dVVYpexCv3c2VNHJutbt27fN5cuXo30JQ5Odu4YVyjpeU5aO1Mku5BMU8g0p7ZuYmDDnz5\/vjBDq+uasOo4d\/bhxZISwvLy8Z\/uuqutSdvlJyyvIrlzK6mRnpwfy37xt28tFXX1p7nSh+oh+I4Q0skt6fADT2HL7l0rZhXpRcdrIJ6SLU+PdPyTZSbvcfhnSCQr3omIfbVMpu3K\/LygNAhBoAwFk14YsUUcIQODABJDdgRFSAAQg0AYCyK4NWaKOEIDAgQkguwMjpAAIQKANBJBdG7IUYB3jtw6lNe\/KlSvmhx9+MCMjI8FdMxhgShvfJGTX+BSFX0H3RvHwW0wLfRBAdj6oE3MPAWRHh6iDALKrgzIxMgmkyc69q8Bug3Ts2DHz4YcfRmXaW8UePHiQuluIvYVONsaUV8i7N9PV0gkgO3qHdwJFZCc7g1hZxa\/Kd39nd3tx7xW2saTRc3Nz0YYCvHQQQHY68tzoVhaR3cLCwp6b\/uVEh7tbcfye0ps3b+7Z6lxAWAHOz893ds5tNCAqVwoBZFcKRgo5CIEisltdXd2zDXvSDr9WdpcuXTLnzp0z9pkcto5JN90fpP58th0EkF078hR0LauWnX3SmgsxvlFm0IBpXEQA2dERvBOoWnbuyM57g6mAFwLIzgt2gsYJVCW79957z3zwwQfRGdv41vQhPpuDHpVPANnlM+IdFROoSnZytnV7e3vfzs2hbIpZcVqCKx7ZBZfS9jWoStnJpSXudXY+No5sX1bCqzGyCy+ntAgCEEgggOzoFhCAgAoCyE5FmmkkBCCA7OgDEICACgLITkWaaSQEIIDs6AMQgIAKAshORZppJAQggOzoAxCAgAoCyE5FmmkkBCCA7OgDEICACgLITkWaaSQEIIDs6AMQgIAKAshORZppJAQggOzoAxCAgAoCyE5FmmkkBCCA7OgDEICACgL\/BWiEviBGSY2LAAAAAElFTkSuQmCC","height":61,"width":101}}
%---
