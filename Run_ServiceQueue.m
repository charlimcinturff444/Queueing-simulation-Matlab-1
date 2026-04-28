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
PBank = zeros([1,nMax +1]) %[output:5b109d54]

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
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:6e366739]

fig = figure(); %[output:3b3c9bd6]
t = tiledlayout(fig,1,1); %[output:3b3c9bd6]
ax = nexttile(t); %[output:3b3c9bd6]
hold(ax, "on"); %[output:3b3c9bd6]

histogram(ax, NumInSystem, ... %[output:3b3c9bd6]
    Normalization="probability", ... %[output:3b3c9bd6]
    BinMethod="integers"); %[output:3b3c9bd6]

plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:3b3c9bd6]

title(ax, "Number of customers in the system"); %[output:3b3c9bd6]
xlabel(ax, "Count"); %[output:3b3c9bd6]
ylabel(ax, "Probability"); %[output:3b3c9bd6]
legend(ax, "simulation", "theory"); %[output:3b3c9bd6]

ylim(ax, [0, 0.3]); %[output:3b3c9bd6]
xlim(ax, [-1, 20]); %[output:3b3c9bd6]


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
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:3f079fb6]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:84c12ea7]
t = tiledlayout(fig,1,1); %[output:84c12ea7]
ax = nexttile(t); %[output:84c12ea7]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:84c12ea7]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:84c12ea7]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:84c12ea7]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:84c12ea7]
xlabel(ax, "Count"); %[output:84c12ea7]
ylabel(ax, "Probability"); %[output:84c12ea7]
legend(ax, "simulation", "theory"); %[output:84c12ea7]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.3$.
ylim(ax, [0, 0.3]); %[output:84c12ea7]
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]); %[output:84c12ea7]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Number in system histogram.pdf"); %[output:84c12ea7]
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
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:04cb978a]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:97e30ae9]
t = tiledlayout(fig,1,1); %[output:97e30ae9]
ax = nexttile(t); %[output:97e30ae9]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:97e30ae9]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:97e30ae9]
xlabel(ax, "Time"); %[output:97e30ae9]
ylabel(ax, "Probability"); %[output:97e30ae9]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:97e30ae9]
xlim(ax, [0, 8]); %[output:97e30ae9]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf"); %[output:97e30ae9]

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
%[text] $Wq=\\frac{{40}^2 }{30\\left(4\*{30}^2 -{40}^2 \\right)}=\\ldotp 02667${"editStyle":"visual"}
%[text] $W=\\frac{L}{\\lambda }=\\frac{2\\ldotp 4}{40}=0\\ldotp 06${"editStyle":"visual"}
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":33.1}
%---
%[output:5b109d54]
%   data: {"dataType":"matrix","outputData":{"columns":10,"name":"PBank","rows":1,"type":"double","value":[["0","0","0","0","0","0","0","0","0","0"]]}}
%---
%[output:12a7dfbd]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:6e366739]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 2.411223\n","truncated":false}}
%---
%[output:3b3c9bd6]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAY4AAADwCAYAAAAXW4N5AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQ2MVtWZxx+2pHHQNTI4KjNIBjtg1hpJMRGCaR1qqUkTWitFPnalTEdDDF9r+Rg+NkKswADDilKLBOkrsDJg05ZC0tSIMikpqyS6HTd1VUTeAgNbR5EYhcadhs1z5bw975lz7z33fe899+t\/k4kyc+75+J3nnP89X88ZcOnSpUuEBwRAAARAAAQMCQyAcBiSQjAQAAEQAAGHAIQDhgACIAACIBCIAIQjEC4EBgEQAAEQgHDABkAABEAABAIRgHAEwoXAIAACIAACEA7YAAiAAAiAQCACEI5AuBAYBEAABEAAwgEbAAEQAAEQCEQAwhEIFwKDAAiAAAhAOGADIAACIAACgQhAOALhQmAQAAEQAAEIB2wABEAABEAgEAEIRyBcCAwCIAACIADhgA2AAAiAAAgEIgDhCIQLgUEABEAABCAcsAEQAAEQAIFABCAcAXCdO3eOWltbqbu7myZNmkTt7e1UU1NTimHdunW0detW7d8CJBMo6N69e2nZsmVW0wyUQSKSufG7o0ePpu3bt1NtbW3QqEIPz3lbuHAhLV++nEaOHBl6\/EmJ8NixY9TS0uJkp1AohFLWV199lTo7O0vtIA22GLQ+1DIGfT+r4SEcAWpW7QDXrl1LU6dOhXD4MBSCKoLpRDdANYQWNIrONLTMhRxR2GXViUTWhCNr5QnTpCAcAWiqwlFfX1\/29YYRhx6m4DJ79mxqa2sLQDzaoGF3ptHmNlmxQziSVR+2cwPhCEBcFQ5+Ve4MVeE4ffq0dnpA7bA4HjGN0NHRQRwPT4fxI0Y18le7\/MUuN+Dvfe979OCDD5ZKtHv3bho3blzp3xcvXqSlS5fSgQMHnN+pwifni6du1qxZQ2fOnCkro4pLvMPhxCPS1fHiMGq+5DhFecTv5GktOT45Dt3vdWnL3HgKYsaMGWXFkf\/uVS5+SWYVtM74\/Wrq4qGHHipNmZqO4nQiKdvOj370I5ozZ45T36pdq3WujiCFnfJ\/xbTpkiVLaO7cuSU71n00qHWtjuB1TVN9R7Yn8Td1KlRmLdLQ1a+uLct5EO\/61Z1bmxTtbciQIWX1Z1LuAN2UlaAQjgCY5c7o61\/\/Oh0+fNh5W3Ri1QqH3PmKbLGx1dXVlRqg+L0wNl1Dkovk14nL+dc1Jq+O3ittzt\/EiRP7dXBe8ek6JA4vOgL+f7HG5CUco0aN0qYrd4hewrF\/\/36nA9Q9Xh2PaZ25CapJXTzzzDO0ZcuWfvbg19l7CYdbE3Dr0PyEg+urt7e3JEKqzfK\/3eraa1TqZm+6Dlm2D7cPNV17032oyfl3s2mdgOm46tioH3ABuqTYgkI4AqCXGzwbWLFYdBbDRce2bdu2ssXxoCMO+eteTkvEzwvxYsQgvo7lTk73RSTCPfXUU07e5IYpOk8RRuSX8+G3DiHnT45TNG65MZhMVcmiJcqh8pYbrZdw8BeduhAsyirnS9eZmpaLzYbTqKTOqqkLXZ51ZVPN2k84vGxH3gAi4vWaquIwXvHxaJpHe7rRJAuO2+K9akfyl7+wQZ2tibyKMIKXnL5utKIroy5+tR3JbVLYqfyhIvKhs\/kA3VGsQSEcAfCrHdmYMWNKnYcsJGpHzEnIjcHrC0gYmq5RcDyqMQsjVTt6uTPhL9Rnn322NEWlFll0pnJn6DWdxOF0jY9\/rzLizQMmwuEWn5xX06kqdcTh9kXn1Qmr0x1edR+kzh599FF67LHHKq4Lv3U2N3P2Eg61rCaLwl7C4Ref14hOFh21LOqIQzc6Ue2I41BHqerI2m2Xn1pGjkue6nVrR2+88YYzYpXjldPU2UvapqsgHFUIB3eK8he2mFKqVDhkgdHNywYRDrmjePLJJ+nxxx\/XTm9wnJUIh1vnosu3iXCYdFamwsHrOm7TbrrGLHM3LZf4aAhaZ+rcfyUiblK2ICMO9aPDpC6CLI6rYcWIy63peXWiblNcuhEOd9D88OjG7cNKzYPb+iFvvWfbFiKky7toR0I4dGtmJvYSoEuKLSiEIwB63de0ulDG0emmfuQveHVqQXzpmxiV24hD\/WpyG3F4Ncogu4ziHnHI5dB9zcnVqtaRuk4hczctV6XCIY84wqgLt7IlWTjcRskBmqITVJ7+0U078YiEH56i9WKtjuJEW\/UacXjFpxNVXdty+zgMyiGO8BCOANR1wqEasJtw6L6I1C\/9aoSD3zVZ49A1ML8Rkg6R3FlHtcahTtfJu4ncdsDIX5nyFJVu6k\/XmE3LVY3Yiy\/uSupCt57hNq0p15vfrir5MGvUIw6xxsH5E52030eLWxm91q7E4rfb1Jnbjj1144k8chAjHq+60wkjhCNAR5u1oG7CweXUbZfl35vMiVbTCfnNF6sNU7eTxLTxqvXpt6tKHI40mapSGcpp6Rba3WyLy8KN2o27bnFc7WBeeukl411VlYi9vAlBLYdfXehGuCIOr905UQmHSJuFvLGxUevFIMhagdeuKt1OODl9+YyQ3B7VOL12tekEQU7jvvvuK61rutUdRhxZ6\/mrLI+XcLi5I9G522ADX7RokZMbXjQPQzj4q8jvHIeuwXhtWzRxwaHOt+s6L1Ph0I3evPbkc3hOTz5HIZdHnQ\/X5U0WP7fFTJGO1wYHZmW6LsW7lKqtC5OyRTniUAUsiHCIXVpqGUwOiPqdvxBllkVGt9FDJ8B+tiby51d3EI4qO9qoXle\/PPx2AOmMPEknmKPihHhBIK8ETKbb8somjHKnbo1DfHHwVybvnmER4a93t73fQjT4a5PFQvx7\/PjxZX6mwoCJOEAABOIloI5i0rbNNV565qmnTjjYMPhR5zPV3wkELDTsOmPjxo0lb6zweGluIAgJAmki4LW2kaZyJD2vqRIOt9FCUCHg8GxgSXHtnXQjQf5AAARAQCaQKuEQi1I82pCd9wURAhHHtGnTMFWFtgACIAACFRDIjXDIC+R+Fwnxdkn+GTZsmPODBwRAAARA4O8EciMccqV7LaizYCxevJhee+01WrBggfODBwRAAARAIKXCEdYah9fOKrHVd8OGDTR27FiMONBaQAAEQEAhkKoRB+c96K4q3fqHiXD4nQ2BJYEACIBAXgmkTjiCnuMQi+G8mC628PLhoD179mh3VYkRB4Qjr00C5QYBEPAjkDrh4AJ5nRxnYWHX1evXryfhMkPn9sNtKy6Ew89k8HcQAIG8E0ilcERZaRCOKOkibhAAgSwQgHAotQjhyIJZowwgAAJREoBwQDiitC\/EDQIgkEECEA4IRwbNGkUCARCIkgCEA8IRpX0hbhAAgQwSgHBAODJo1igSCIBAlAQgHDEIR7FYpB07dlBXVxedLhapj4hmzZpFK1eujLKuETcIgAAIhEIAwmFZOFg0Jk6YQKuLRZpCRAOI6BIR\/YKIVjQ20rZCgZqbm0OpXEQCAiAAAlEQgHBYFA4hGkeLRRqsqc2PieiOxkY6duJEFHWNOBNCQHhfTkh2kA0LBLLmaRvCYVE4nnvuORrU0kL3exjqC0R0oVBwpq7wZI+A7H05e6VDidwIsMNUdpyalWsaIBwWhEN8YS5btoxe6epypqfcHp62GtXURLt27cJ9IBnsh2Tvyw0NDRksIYqkEuArGp588knKkv87CEfEwiF\/YZ49dYou9vFSuPdTM3AgDb3xRsete5a+UvzKnYe\/wzNBHmq5vIxZrHMIR8TCIYzma\/f\/mA7+vJ3O9\/b4jjiG33IH3Xrnt+mdg89n6islf11G\/xK7dSJZWffI2lx+GDYL4QiDYsLjCLuSRXx3zl5HH5w8Tq0\/W+a7xvHElLnUdPs36A9b2yAcCbeXoNnT2ReLxoNzHqF3\/\/v1oNElLnyQUbLOk3UYBeJrE44cOULt7e1UU1PjGqW4l2f69OnE1y5ElZ+w+5QwGFUbB0YclkYcLBzX3nQb7ZxzN73X2+O6q6qproFmPv0yffj+mxCOaq07ge\/rOhF5VDpo8PUJzLVZlj48\/mYiRsmVCodZKYOHgnAEZ5a6N8KuZHnEwcLxSW8P7Vs1k7b09vQ7x\/FwXQPdu2onXV3XAOFIneWYZdhLOMTHhVlMyQvl9rHDHTlvDOGnvr6eCoWCc1eO\/IXPf1uzZg1NmTKF5s6d64SdPXs23XfffdTS0kJnzpyh0aNHO5ev8dPa2upczMYjBX5ksdi\/f3\/ZiINvDd26dWsJGMc7f\/58Wrp0KR04cMD5\/dq1a2nMmDFld\/mo9\/hwmKlTpzrhOc4rr7ySXn75Zeru7nZ+57b4HXafkoSax4jD8oiDk2PxeKvr13T6T0fpQm+Pc3L8lubv07gpXzQYfjDiSELzCD8PeRMO9epm+d8fffRRqaNm0iwQkyZNcgRB3PRZV1fniAVPOXFHP378eJo4caKxcDz11FOO6IhpK5k\/CxHHqZuqGjJkiJPGtGnTHLEQIiL+zcLBoiNEMG+3ikI4YhAOk+4IwmFCKX1h8i4cco2pIw755k6x\/sBCIb7yuXPmQ7QPPfSQsXCoaxxCAFicvITjjTfe6LdOIovetm3bnKKI66i91kcw4khfOw2c47ArWZ2qMs0QhMOUVLrC5U04hACIKSF5OsdEOMRoQExHVSoc8nSZmFbyEo5f\/epXZcLA\/+D88nTaxo0bCcJx6RKfOcNzmQCEA6YQJYG8CYfMUqw1iHUO\/psYZcj\/z+sf6o6nSoWD1zt4fUW3PgLhqNzSMVWFqarKrQdvBiaQZ+FgWPIUlLwYHYVwPProo\/TYY4+V1jA4DUxVBTZZ7QsQDghHOJaEWIwI5E041MVxt+mpIMIhdkTxyIXXGIQYDB8+3FkEF7uqhHCIdRJ52oynzKpdHOc8Y43DyOyzHwhTVdmv4zhLmDfhYNbqdlixzlHpGoe860ps0+UF8xdffLFMOFhE+HCl2M7LeXn22WfpN7\/5jbMtmOMRax9i66+8QO+3HRfCEWdLSljaEI6EVUjGsuMlHDd\/65\/p2q\/cltoSX\/j4L\/RfL\/w7vB1EPIuRBAPBVFXElYxdVUkw8+Tkwc3lyOLFi4m9qKb9CeJyJO1lNc1\/2B+jpulGGQ7CAeGI0r4Qt6F9wclhdk0FwpHdui2VLOxKxogjB0YToIhh21eApBE0JgJZrHOMOAy\/CCu1OQhHpeSy+V4WO5Fs1lR4pcpinUM4IBzhtRDE5Esgi52IV6FtuS73BR9jgCzWOYQDwhFjk8pf0rY7EXbRsWPHDurq6qLTxaLjUJPvs1+5cqUV+BAOItt1bqNiIRwQDht2hjQuE7DZibBoTJwwgVYXi\/1c+K9obKRthQI1NzdHWjcLFizQui7\/6le\/6mzb5Yc94sqXLrm5YeewfmcrrrvuOsebLntSuvnmm+mee+4pOUmUT40Ld+yRFj6GOrdRHk4DwgHhsGVrSIfsfX0K0ThaLLpeGnZHYyMdO3Ei0nrRjThk9+mqu3L1Eib55Dln1M\/VOYdn4aitrS27o4O95PLfOjs7fW8GDBuIzY+FsPPuFp814ZC\/FNQvDFuFNUkn7ErG4rgJ9fyECdu+3Mg999xzNKilxfea4guFgjN1FdVjMlXFJ8v54dPfCxcupOXLlzsXPYmH\/97Y2Oj8U70SVhYWncda4c2WhUTEI9y0R1VmNV5bdW6rPLGMOFT3xkkTkbArGcJh05yTn1bY9uVW4gkTJtArXV00wAMJu8X+ZnMzHTp0KDJwQYRDvu1PzRDfvsejKH6Efyj+fy9X53La7Jdq9erV9MMf\/rBMlCIruBSxrTq3URaRhrURh65QqoiwvxjZKGyCEGmFXckQjjhqMblphm1fbiUdOWIEHbvc0XrRGBnxdFVQ4ZB9Ran5FiMTU+Hg98XlTyxKvElgxYoVzm2CNh9bdW6zTLEKhzwUVe8EjktAwq5kCIdNc05+WmHbl1uJR4wYQe8Xi6kacehu9pPLp65\/8N+8pqrkEcntt99OfA2t7WkqkccZM2ZkyodXLMKh7oyQL7AXDSuu0UfYDRvCkfzO3GYOw7Yvt7ybrnH8z6pVkW7NDTLiEN5q9+zZU1rglndCjRo1yndxXJ3KEum\/\/vrrpfvBbdY3hKNK2qpYcHTyNZLql4VsPFUmHej1sBs2hCMQ\/swHDtu+PKehRoyguHdViekivoVP57qc\/65OQbm5YeewfttxVeEQ6auL6jYNzWad2yqXtRGHuu3Oq4A8JIVwvEl\/2NqWqeGtLaNOcjo2OxG\/cxwvHTpU2q2UZGbV5o37E37imKbCiKPa2gvxfdH4RJRuIxfxd955IV\/m4rWTK+yGjRFHiBWfgajCti8\/JHGfHPfLX9R\/56mquHZTibLZrvOomXL8Vkccuj3aopCmowwhAh0dHcSnP7lSFi1a5Dp\/qYYXQ2O+OUw+rVpJJZs0SgiHDTNOTxpZ7ESSSl+w5q28cY02MOKo0jp4qioM4dBtydP9ThYkdX5TvrJSPmjkV8nynQl9fX3U8sADru4cVv7kJ9TU1EQ9PT3El\/TcOXsdXXuT+e1uH76PqaoqTS6Rr0M4ElktkWYqi3Ue6YhDvhzepGb8vgxEfOLyeXmUEMSVQCXCwaIhbmlj0eg9e5bO9PW5unOoHziQht54Y6nYEA4TC8h+GNGJsA8nvi0PT\/YJiI9Hvyn1NJGIVDhkEH4jDhNobk7K5L3c7FrA7\/GaFnP7OhC\/\/9r9P6Zi9xFq+12nrzuHzdP\/la666ip65+DzGHH4VUpO\/i5\/gOSkyCgmkfORsGHDBho2bFgmeFgTjjBohSEcfsNG+Ytw8uTJpYqW1yq6dnbQybeO+h6uGn7LHdQ8c5GzOwojjjAsIBtxZOWa2GzUhp1SsGBkRTSYWK6Ew2SxTN6xxdMJ\/COvfbAA\/HbjI\/RRb4+vxQ2pa6DvLHwCwuFLCgFAAATSRCBS4RAjhOHDhxP7oJk7dy51d3e78mFHZMIlsi5QNWscJqIhCwQPK3l4Kb4S5BHH\/o2P0PneHow40mTpyCsIgEBoBCIVjtByKUUUdFeVLAYmi1N+axw84vjg5HFq\/dky3zWOJ6bMpabbv4ERRxSGgDhBAARiI5A64QjjHIcXbRPh4G21O+fcTe\/19rjuqmqqa6CZT79MYlst1jhis3EkDAIgEDKB1AmHPIIQLOSRhLrVVvV7I\/PTjUBMheOT3h7at2ombent6Xct58N1DXTvqp10dV0DhCNkg0V0IAAC8ROIVDh0jg29iuy3xmEDl6lwcF5YPN7q+jWd\/tNRutDbQ31EdEvz92nclLmlrGLEYaPWkAYIgIBNApEKh82ChJVWEOEwSTNM4TBxcWKSJ4QBARAAgWoIQDgUekkVDj9Pp9sKBWpubq7GFvAuCIAACBgRiFQ4wt6Oa1SiKgMlUThuuOEGmjhhQiLuVqgSL14HARDIAIFIhSONfJIoHG+\/\/TYNamnx3f57oVCgWbNmpRE78gwCIJAiAhCOhE9V8cn1ffv20StdXb4HDkc1NdGuXbucQ4tZcm+QovaErIJALghAOBIuHJy9s6dO0cU+3rPl\/dRc9sibNYdqfuXG30EABOwSsC4cui26Xjfy2cVBzsVQM2bM6Hdla7UXMlV6AJC98R78ebuxi5Nb7\/y2443X5JS8bbZIDwRAIBsErAqHm78odnO+efNm11v8bKJOmnBU6uIEwmHTapAWCOSLgDXhEA4K6+vrqa2trR9lPuHtdp2rzSpJonBU4uIEwmHTapAWCOSLgDXhEFNU06ZN097\/a3rneNTVk1ThCOriBMIRtaUgfhDILwFrwoERR2V3jstrI0FcnEA48tuoUXIQiJqANeHgggjPtvPmzSsbdWCNo381h+mqJGojQvwgAAL5IhCpcGTdyaGJqVQrAJXuxsKIw6R2EAYEQKASApEKRyUZivudpK5xmHIRQgXhMCWGcCAAAkEJQDgUYhCOoCaE8CAAAnkjYFU4\/Kau0nYfh4mxYKrKhBLCgAAIpImAVeGQz2rs37+f2FU4n+lQb+2LEyBGHHHSR9ogAAJpIGBNONRzHNxBd3Z2Unt7O9XU1BDvrBJCEic4CEec9JE2CIBAGgjEJhw8ylizZg1t3LiRamtrnVGH\/O+44EE44iKPdEEABNJCwJpwiAOA48ePd85w8Ahk4cKFtHz5cho5ciSEQ7GYatdGsKsqLU0Q+QSB9BGwJhyMRnUrwmsejY2NjpDw344cOVKauooLJUYccZFHuiAAAmkhYFU4GIq8QM6jkNbWVuru7qYk7Kji\/EE40mK6yCcIgEBcBKwLR1wFNU0XwmFKCuFAAATySgDCodQ8hCOvTQHlBgEQMCVgXThwA6BZ1WBx3IwTQoEACNgnYFU4cAPgbcY1DOEwRoWAIAAClglYEw7cx1H9fRwmtgEnhyaUEAYEQKAaAtaEAzcAQjiqMVS8CwIgkBwC1oQDIw4IR3LMHjkBARCohoA14eBM4gZArHFUY6x4FwRAIBkEIhUOPzfqKoIkHALM4nZcdh65Y8cO6urqotPFIvUR0axZs2jlypXJsELkAgRAIFUEIhWOVJG4nNmsCQeLxsQJE2h1sUhTiGgAEV0iol8Q0YrGRtpWKFBzc3Maqwp5BgEQiIkAhEMBnyXhuOGGGxzROFos0mCNgX1MRHc0NtKxEydiMj8kCwIgkEYC1oVDrHOcOXOmxKu+vp4KhYLjJTfuJ0vC8fbbb9Oglha63wPqC0R0oVBwpq7wgAAIgIAJAavC4XUAcNmyZZQEV+BZEg5m+kpXlzM95fbwtNU3m5vp0KFDJvaCMCAAAiBA1oQD23HtbsddsGAB\/XTTJjpWLPqaec3AgXTo8GEaNmyY84MHBEAABLwIWBMOHAC0Kxxc6adOnaLP+\/p8RxyDrriChg4dSmPHjqUNGzZAPNBngAAIeBKwJhwYcdgVjq\/d\/2P64ORxmte5yXeNY\/W3plD9iJvpnYPPJ2K6EG0WBEAg2QSsCQdjwBqHvQOAd87+Qqh2zrmb3uvtcd1V1VTXQDOffpng4yrZDRW5A4EkEbAqHFzwMHZVCQESIIMsqsvX1eoqIiuL40I4PuntoX2rZtKW3p5+5zgermuge1ftpKvrGiAcSWqVyAsIJJyAdeGolocQno6ODho3bpwzilm0aJHRdl4Wja1bt9LatWude87zIBxcRhaPt7p+Taf\/dJQu9PY4J8dvaf4+jZsyt4QAI45qLRPvg0B+CFgTDrHGMX36dKfDr\/Thzp+ftra2UhS638nxi4X53t5eqquro2nTpuVKOExYQzhMKCEMCIAAE7AmHH67qkyqQ4jP+PHjyzp+HnV0dnZSe3s71dTU9Itq7969xK435s+fT0uXLiX1ffmFrE1VmXDlMBAOU1IIBwIgYE043Dr9IFUgxIdHG\/KohTt7HnVs376damtrXaM0yYMQDj4HMXny5NLWVPF7sXZgmu9qb\/KznV6Q9SJTBggHAiCQLQLWhIOx8frEkiVLaP369RW5F7EpHJxfFg\/+4QfCkS3DR2lAAAQqJ2BNOExcrPu5VbcpHHwQjg\/EiZPUEI7KjQxvggAIZIuANeEIA1ulaxwi7SBTVeqUDYQjjBpEHCAAAlkgkCrhYOCV7KqCcPibKhbH\/RkhBAiAwBcErAgH72piT63iqWYBtppzHBhxuJs9hANdAgiAgCmByIWDRWPz5s2lA3pu946bZpjDeZ0c91qAh3BAOILYGcKCAAjoCUQqHG4dNYvJkSNHXM9dxFlZOMexu7TVGXeVx2mJSBsEkksgUuFwO\/Rneu4iDmwQji+EA3eVx2F9SBME0kEgNuEw9S9lGyOEYzfhrnLbVof0QCBdBCAcSn1BOHYT7ipPVyNGbkHANgEIB4TDISDvqsJd5babIdIDgXQRgHBAOMqEA3eVp6sBI7cgEAcBK8LR3d1tVDY\/lyNGkVQZKO9TVYwPd5VXaUR4HQQyTiBS4Ugju7wLB+4qT6PVIs8gYJcAhANTVWVTVbir3G4DRGogkEYCEA4Ih1Y4cFd5Gpsz8gwCdghAOCAcWuHgX+KucjuNEKmAQNoIQDggHK7CYWLMcI5oQglhQCBbBCAcEA4IR7baNEoDApETgHBAOEIXDjhHjLzdIgEQiJUAhAPCEapwwDlirO0ZiYOAFQIQDghHaMIB54hW2iwSAYHYCUA4IByhCQecI8benpEBELBCAMIB4QhNOOAc0UqbRSIgEDsBCAeEIzTheGD6dDpWLPoa9cjGRjp24oRvOAQAARBIJgEIB4QjFOFgr7qbNm2i94tFGuBh65eIaFRTE+3atYuGDRvm\/OABARBIFwEIB4QjFOHgSD799FP6aW8v3e\/RBl4gotnXXEODBw+msWPH0oYNGyAe6eozkFsQIAgHhCMU4WCvuoMGX0+\/3fgIvdfbQ4M1jetjImqqa6DvLHyCPjz+Jr1z8HnavfuLO87xgAAIpIcAhAPCEYpwCK+6lTpHxKHB9HQayCkIQDggHKEKB0cW1DmiOP+xulikKUTOGgmvhfyCiFY0NtK2QoGam5vRWkEABBJCAMIB4QhdOExsWzhHXLt2Lf3b0qV0tFh0nd66A7uwTJAiDAhYIwDhgHDEKhz33HMPTXjmGd8F9QuFAs2aNctaw0BCIAAC7gQgHBCOWIXj7NmzdOGvf8UWXvRSIJAiAhAOCEe8wnHqFF3s6\/NtMjUDB9LQG2\/EFl5fUggAAtETgHBAOGIVjlOnTtHnfX2+I47ht9xBt9757X5beLEbK\/pOAimAgEoAwgHhiFU4Bt88jtp+1+m7xvHElLnUdPs36A9b20pnP+DCHR0aCMRDAMIB4YhVOPj8h8mhwZlPv0zyNbVw4R5Ph4FUQYAJQDggHLELx5f\/cQjtWzWTtvT29DvH8XBdA927aiddXddQJhxw4Y4ODATiIwDhgHDELhzX3nRb4EOD1bpwx9pIfJ0OUk4\/AQgHhCMRwmHSlMRUFXvi\/emmTUYu3Hk31qHDh8s88WJtxIQ2woCAOwEIB4QjdcLBGTbdjTXoiito6NChpW28fX19NHHChIp+dmoTAAAJaElEQVRPqmOkgu4UBLDG0c8GXn31VZoxY0Y\/r63i98KZn6nxiK9kvFdOrBIu4h32xPvByeM0r3OT726s1d+aQvUjbi5t461mbQQjFVOrR7isE8CIAyOO1I04hAjvnHO3rwt3eTcWT3Ht27ePXunq8j03ol42JUSjUp9aGKlkvSvNV\/kgHBCO1ApHUBfuXNCzFZ5UP3jwIA1qafEd4eh8amGkkq9ONQ+lhXBAOFIrHJzxIC7ceYrr4M\/b6Xxvj++IQz6pHudIJQ+dEMqYPgK5EI6LFy\/S0qVL6cCBA04NTZo0idrb26mmpgZrHJcJVLLmwK\/afC+MtHhtpPVny3xHDvJJ9bhGKunrTpDjvBDIhXCsW7eOzpw544gFPywi9fX11NbWBuHImXDwmZGgayNxjFTy0gGhnOkkkHnhOHbsGC1ZsoTWr19PI0eOdGpJ9ztRfdhVtY64czV9whgFmKYXVlpB10Z4Md7mSOUHP\/gBNTQ0mFaBE27YsGHODx4QsEEg88LBQsAjju3bt1Ntba3DVExdTZ8+ncaNG1fGuRLh+Oyzz+j999+nm266ia688sqy+MLq7EyNIUnphc0lzLIFWRupdBdXpSMV07qWw40dO5YqEZxK0gpbpE6fPk2\/\/OUvafLkyRC\/yxWSdCaZF469e\/fSkSNHytY0hHCMHz+epk6dqhUOXhDlxiienp4eWrx4MY28dyFd+5XyL3LuIFlwbr31Vrr++uvL4rv4l+P0x\/94TPueV6PNwnthc4mbyScf9NBLHQ\/Tzgvn+\/nUmjnoGpq4aAtdfV0Dyfn87Nz\/0vwdj\/uuqTz+nRbH+y\/bSsNd\/0KDBpfbkZ+tnP7PfZVoQEXvhC1Som2pba6izGXkJcFk9+7d\/T5uk1BECIciHKz0LBCvvfZav\/q59OWr6K9N3yb+r+kz4PNPaeC549RX+xW8J0GrhEsl73CSYb73twvn6eKf\/0j\/9+GfacCF88RXUF0xfDRd9U\/NpdKp6Z1\/8Uk6e+G8653qQwddQ9fcs6DqfP7tKnOx4cz+w+efOWkGeY\/f+dK59+hLn\/7FtAkgXBUEfv\/73ydyFAbhUISD65jFg3\/wgEAYBNjNScsDD9DqYrHfSGVFYyMVdu2igQMHhpEU4sgYAXUqPSnFy7xwBF3jSErFIB\/ZIoCT49mqz7yXJvPCEXRXVd4NAuUHARAAAT8CmRcOBhDkHIcfMPwdBEAABPJOIBfCEeTkeN4NAuUHARAAAT8CuRAOPwj4OwiAAAiAgDkBCIc5K4QEARAAARDgLe6XLl26BBIgAAIgAAIgYEoAwmFKyiUc1k\/6gxFuW+S\/jB49usztS5XYU\/U6b85obGzs56WAf79161anLHnko+PCuyBbWlocp6TiYYekhUKh5GsuVZVvkFm1zDrv3UmzFQiHQcV6BcGOrf50dG5eqsSc2tdFg1+7dm2ZcDCjPXv2lMRUtiOdu\/\/UAnDJuBsX3bmrrJVdLo8QjY6OjpJrEdUWkmgrEI4qrBJnRPTw2PD50bmtrwJ3ql49d+4ctba2Um9vL9XV1dG0adNKwiH+xnzEyWDd71JVYMPMenHhKPL20aErr9yvDBkyxLGjpNkKhMPQ4HXBcCq9PxUvB5JVoE7dq9wh8Gnx+fPnO\/e\/yA413dz6u01ppa7wHhn24sKv4aOj\/NoHZqJeCyE46aY\/bdkKhKMK0kE971aRVGpe5S\/KhQsX0vnz56m7u9vJdx7n70WF6YTUbTomT52mjov4HdvO4cOHHYRZX9\/QNWx5aurdd9\/tdy1EEgQWwlFFlwzh6A9PzNnOmzevNDWjztFWgTx1r0I49FWm4yKmsXj6TkxzssguWrQo04vjMiH1PqCkfmRAOKroiiAcZvBEhyDP85u9mf5QEA5z4dCFFPzcrnpOv4X8vQRCNOSNFBCOLNXw5bJgjcOsUvO87qEre57XOLym8NysKQ9TeDrRYB5JtRWMOMz6Pm0o7Krqj0UnpnnZMeT1xSwvjud5V5WXcOjaUx4+Otyuq2ZWSbUVCEcVwiEWqfiwUnt7uxMT76DJw7DaDZtuWipvZxRkNm4dXxL35lfZFAK97rU4LrefrK+P6c5xqCCTaCsQjkDm3j8wTo73ZyLEQ+yq0p2ErRJ7al73+mJO2mlgm1DduKjtKes78mQbUPnL940nzVYgHDZbC9ICARAAgQwQgHBkoBJRBBAAARCwSQDCYZM20gIBEACBDBCAcGSgElEEEAABELBJAMJhkzbSAgEQAIEMEIBwZKASUQQQAAEQsEkAwmGTNtJKPAF1OyhnOAlbQnk75l133VVyw554kMhgpglAODJdvShcEALiBO\/s2bPL7hIRe+jlffVB4q02rMkhsWrTwPsgEIQAhCMILYTNLAGdV1+5sCweLCzbt2+n2tpaqxwgHFZxIzEDAhAOA0gIkn0CfsJw\/PhxuuKKK4ivdRXCod6tLp+Qd\/PqqvolEu4k2I04uw8Xd20LD6leaWS\/VlDCpBKAcCS1ZpAvawREJ88Jss8xkzu\/ucNftmwZiekrEcfJkyedUQnHofNbphMOjkcWHTVujDismQISMiQA4TAEhWDZJaC7QMirtG73i8jTXd\/97neNhWPz5s1lFxWp8UM4smt7aS0ZhCOtNYd8h0YgqHC4deTy9JS4a1z1lOw2VSWvnUA4QqtaRBQRAQhHRGARbXoIBJ2qcrs\/IWzhEFeoYsSRHlvKS04hHHmpaZTTk4DfvQ\/yNNSYMWOopaWFOjo6ys5VQDhgZHkhAOHIS02jnJ4ETLbjHjhwwFmLGDJkCLW2tjqiwbuhxGOyxqEufOsES506w4gDxps0AhCOpNUI8hMbAb8DgGKLLGfQb1cVb9nlMPLCtxAA3nIrdmOZCIfbYnxsoJBw7glAOHJvAgAgE1BvL+S\/ubkcUc9YqCfO+V315jZxXkNMc5kIhxxPEtyfwGJAAMIBGwABEAABEAhEAMIRCBcCgwAIgAAIQDhgAyAAAiAAAoEIQDgC4UJgEAABEAABCAdsAARAAARAIBABCEcgXAgMAiAAAiAA4YANgAAIgAAIBCIA4QiEC4FBAARAAAQgHLABEAABEACBQAQgHIFwITAIgAAIgACEAzYAAiAAAiAQiACEIxAuBAYBEAABEIBwwAZAAARAAAQCEYBwBMKFwCAAAiAAAhAO2AAIgAAIgEAgAhCOQLgQGARAAARAAMIBGwABEAABEAhE4P8BvL3BTDsDC78AAAAASUVORK5CYII=","height":192,"width":318}}
%---
%[output:3f079fb6]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 2.411223\n","truncated":false}}
%---
%[output:84c12ea7]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAY4AAADwCAYAAAAXW4N5AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQ2MVtWZxx+3rMtga2RwKswgGSkfWWskhQQIpjqjIokJLRURcFfKdDTEgBDLxwzQCLECw9f6QS1MkL4CKwNt2lJImhpRJiFlK4lup5u6VUTeMgxsHUVidXDZMWyei+f1zOHce89533vvez\/+NyGt8557Pn7nOed\/z9dzrrp06dIlwgMCIAACIAAChgSugnAYkkIwEAABEAABhwCEA4YAAiAAAiBgRQDCYYULgUEABEAABCAcsAEQAAEQAAErAhAOK1wIDAIgAAIgAOGADYAACIAACFgRgHBY4UJgEAABEAABCAdsAARAAARAwIoAhMMKFwKDAAiAAAhAOGADIAACIAACVgQgHFa4EBgEQAAEQADCARsAARAAARCwIgDhsMKFwCAAAiAAAhAO2AAIgAAIgIAVAQiHFS4EBgEQAAEQgHDABkAABEAABKwIQDgscJ07d44aGxupo6ODpk6dSi0tLVRRUVGIYf369dTa2qr9zSIZq6D79u2j5cuXR5qmVQaJSObG744ZM4Z27NhBlZWVtlEFHp7ztnjxYlqxYgWNHDky8PjjEuHx48epoaHByU4ulwukrH\/4wx+ora2t0A6SYIu29aGW0fb9tIaHcFjUrNoBrlu3jmbOnAnh8GEoBFUE04muRTUEFjSMzjSwzAUcUdBl1YlE2oQjbeUJ0qQgHBY0VeGorq7u8\/WGEYcepuAyb948ampqsiAebtCgO9Nwcxuv2CEc8aqPqHMD4bAgrgoHvyp3hqpwnD59Wjs9oHZYHI+YRti0aRNxPDwdxo8Y1chf7fIXu9yAv\/vd79LDDz9cKNGePXto4sSJhf++cOECNTc308GDB52\/qcIn54unbtauXUtnzpzpU0YVl3iHw4lHpKvjxWHUfMlxivKIv8nTWnJ8chy6v+vSlrnxFMSDDz7Ypzjy717l4pdkVrZ1xu+XUhePPPJIYcrUdBSnE0nZdn7wgx\/Q\/PnznfpW7Vqtc3UEKeyU\/1dMmy5btowWLFhQsGPdR4Na1+oIXtc01XdkexK\/qVOhMmuRhq5+dW1ZzoN416\/u3NqkaG+DBg3qU38m5bbopiIJCuGwwCx3Rt\/+9rfpyJEjztuiEytVOOTOV2SLja2qqqrQAMXfhbHpGpJcJL9OXM6\/rjF5dfReaXP+Jk+efEUH5xWfrkPi8KIj4P8v1pi8hGPUqFHadOUO0Us4Dhw44HSAuser4zGtMzdBNamLbdu20datW6+wB7\/O3ks43JqAW4fmJxxcX93d3QURUm2W\/9utrr1GpW72puuQZftw+1DTtTfdh5qcfzeb1gmYjquOjfoBZ9EllS0ohMMCvdzg2cDy+byzGC46tu3bt\/dZHLcdcchf93JaIn5eiBcjBvF1LHdyui8iEe65555z8iY3TNF5ijAiv5wPv3UIOX9ynKJxy43BZKpKFi1RDpW33Gi9hIO\/6NSFYFFWOV+6ztS0XGw2nEYxdVZKXejyrCubatZ+wuFlO\/IGEBGv11QVh\/GKj0fTPNrTjSZZcNwW71U7kr\/8hQ3qbE3kVYQRvOT0daMVXRl18avtSG6Twk7lDxWRD53NW3RHZQ0K4bDAr3ZkY8eOLXQespCoHTEnITcGry8gYWi6RsHxqMYsjFTt6OXOhL9QX3jhhcIUlVpk0ZnKnaHXdBKH0zU+\/rvKiDcPmAiHW3xyXk2nqtQRh9sXnVcnrE53eNW9TZ098cQT9OSTTxZdF37rbG7m7CUcallNFoW9hMMvPq8RnSw6alnUEYdudKLaEcehjlLVkbXbLj+1jByXPNXr1o7efPNNZ8QqxyunqbOXpE1XQThKEA7uFOUvbDGlVKxwyAKjm5e1EQ65o3j22Wfpqaee0k5vcJzFCIdb56LLt4lwmHRWpsLB6zpu0266xixzNy2X+GiwrTN17r8YETcpm82IQ\/3oMKkLm8VxNawYcbk1Pa9O1G2KSzfC4Q6aHx7duH1YqXlwWz\/krfds20KEdHkX7UgIh27NzMReLLqksgWFcFig131NqwtlHJ1u6kf+glenFsSXvolRuY041K8mtxGHV6O02WVU7hGHXA7d15xcrWodqesUMnfTchUrHPKII4i6cCtbnIXDbZRs0RSdoPL0j27aiUck\/PAUrRdrdRQn2qrXiMMrPp2o6tqW28ehLYdyhIdwWFDXCYdqwG7CofsiUr\/0SxEOftdkjUPXwPxGSDpEcmcd1hqHOl0n7yZy2wEjf2XKU1S6qT9dYzYtVyliL764i6kL3XqG27SmXG9+u6rkw6xhjzjEGgfnT3TSfh8tbmX0WrsSi99uU2duO\/bUjSfyyEGMeLzqTieMEA6LjjZtQd2Eg8up2y7LfzeZEy2lE\/KbL1Ybpm4niWnjVevTb1eVOBxpMlWlMpTT0i20u9kWl4UbtRt33eK42sG88sorxruqihF7eROCWg6\/utCNcEUcXrtzwhIOkTYLeW1trdaLgc1agdeuKt1OODl9+YyQ3B7VOL12tekEQU7jvvvuK6xrutUdRhxp6\/lLLI+XcLi5I9G522ADX7JkiZMbXjQPQjj4q8jvHIeuwXhtWzRxwaHOt+s6L1Ph0I3evPbkc3hOTz5HIZdHnQ\/X5U0WP7fFTJGO1wYHZmW6LsW7lEqtC5OyhTniUAXMRjjELi21DCYHRP3OX4gyyyKj2+ihE2A\/WxP586s7CEeJHW1Yr6tfHn47gHRGHqcTzGFxQrwgkFUCJtNtWWUTRLkTt8Yhvjj4K5N3z7CI8Ne7295vIRr8tcliIf570qRJffxMBQETcYAACJSXgDqKSdo21\/LSM089ccLBhsGPOp+p\/k0gYKFh1xmbN28ueGOFx0tzA0FIEEgSAa+1jSSVI+55TZRwuI0WbIWAw7OBxcW1d9yNBPkDARAAAZlAooRDLErxaEN23mcjBCKOWbNmYaoKbQEEQAAEiiCQGeGQF8j9LhLi7ZL8b+jQoc4\/PCAAAiAAAl8SyIxwyJXutaDOgrF06VJ6\/fXXadGiRc4\/PCAAAiAAAgkVjqDWOLx2Vomtvhs3bqQJEyZgxIHWAgIgAAIKgUSNODjvtruqdOsfJsLhdzYElgQCIAACWSWQOOGwPcchFsN5MV1s4eXDQXv37tXuqhIjDghHVpsEyg0CIOBHIHHCwQXyOjnOwsKuqzds2EDCZYbO7YfbVlwIh5\/J4HcQAIGsE0ikcIRZaRCOMOkibhAAgTQQgHAotQjhSINZowwgAAJhEoBwQDjCtC\/EDQIgkEICEA4IRwrNGkUCARAIkwCEA8IRpn0hbhAAgRQSgHBAOFJo1igSCIBAmAQgHBELRz6fp507d1J7ezudzuepl4jmzp1Lq1atCrOeETcIgAAIBEYAwhGhcLBoTK6vpzX5PM0goquI6BIR\/YKIVtbW0vZcjurq6gKrXEQEAiAAAmEQgHBEJBxCNI7l8zRQU5MfEdH42lo6fvJkGPWMOGNEQHhfjlGWkJWQCaTN0zaEIyLhePHFF2lAQwM94GGgPyeinlzOmbrCk04CsvfldJYQpdIRYIep7Dg1Ldc0QDhCFg7xdbl8+XJ6rb3dmZ5ye3jaatSIEbR7927cBZLS\/kf2vlxTU5PSUqJYMgG+ouHZZ5+lNPm\/g3CEKBzy1+XZzk660MtL4d5PRb9+NOTGGx2X7mn6QvErd1Z+h2eCrNT0l+VMY51DOEIUDmEw33rgh3ToZy10vrvLd8Qx7ObxdMtt99Dbh15K1RdK9roLfYndOpG0rHukbS4\/CLuFcARBMeZxBFnJIq7b5q2n90+doMafLvdd43h6xgIaMe52+n1rE4Qj5rZSTPZ09sWi8fD8x+md\/3qjmChj9Y7NSFnnyTqIwvC1CUePHqWWlhaqqKhwjVLcyzN79mziaxfCyk+QfUoQfIKIAyOOCEYcLBzXD7+Vds2\/i97t7nLdVTWiqobmPP8qffDenyAcQVh3DOPQdSLyyHTAwBtimGuzLH1w4k+xGCkXKxxmpbQPBeGwZ5a4N4KsZHnEwcLxcXcX7V89h7Z2d11xjuPRqhqatnoXXVtVA+FInNWYZ9hLOMQHhnls8Qrp9sHDHTlvDuGnurqacrmcc1eO\/IXPv61du5ZmzJhBCxYscMLOmzeP7rvvPmpoaKAzZ87QmDFjnMvX+GlsbHQuZuORAj+yWBw4cKDPiINvDW1tbS3A4ngXLlxIzc3NdPDgQefv69ato7Fjx\/a5y0e9x4fDzJw50wnPcV5zzTX06quvUkdHh\/M3t8XvIPuUuNQ4RhwRjjg4KRaPt9p\/Taf\/fIx6uruck+M3132PJs643Fj4wYgjLs0j+HxkTTjUq5vl\/\/7www8LHTWTZoGYOnWqIwjips+qqipHLHjKiTv6SZMm0eTJk42F47nnnnNER0xbyfxZiDhO3VTVoEGDnDRmzZrliIUQEfHfLBwsOkIEs3arKIQjYuEw6YogHCaUkhkm68Ih15o64pBv7hTrDywU4iufO2c+SPvII48YC4e6xiEEgMXJSzjefPPNK9ZJZNHbvn27UxRxHbXX+ghGHMlsq1a5DrKS1akq04xAOExJJS9c1oRDCICYEpKnc0yEQ4wGxHRUscIhT5eJaSUv4fjVr37VRxj4Pzi\/PJ22efNmgnBcusTnzvB8QQDCAVMIk0DWhENmKdYaxDoH\/yZGGfL\/5\/UPdcdTscLB6x28vqJbH4FwFG\/pmKrCVFXx1oM3rQlkWTgYljwFJS9GhyEcTzzxBD355JOFNQxOA1NV1iarfQHCAeEIxpIQixGBrAmHujjuNj1lIxxiRxSPXHiNQYjBsGHDnEVwsatKCIdYJ5GnzXjKrNTFcc4z1jiMzD79gTBVlf46LmcJsyYczFrdDivWOYpd45B3XYlturxg\/vLLL\/cRDhYRPlwptvNyXl544QX6zW9+42wL5njE2ofY+isv0Pttx4VwlLMlxSxtCEfMKiRl2fESjtF3\/wtd\/41bE1vino\/+Rv\/583+Dx4MQZzHiYhyYqgqxkrGrKi5mHp98uLkcWbp0KbEX1aQ\/Ni5Hkl5W0\/wH+TFqmmbY4SAcEI6wbQzxSwTcOhE4OUyvmUA40lu3hZIFWckYcWTAYCyLGKR9WSaN4GUikMY6x4gDI44yNadsJpvGTiSbNWle6jTWOYQDwmHeAhCyZAJp7ES8oETlurzkigkxgjTWOYQDwhFik0HUKoGoOxF20bFz505qb2+n0\/m841ST77RftWpVJJUD4SCKus6jqFgIB4QjCjtDGl8QiLITYdGYXF9Pa\/L5K9z4r6ytpe25HNXV1YVaN4sWLdK6Lv\/mN7\/pbNvlhz3iypcuublh57B+Zyu+\/vWvO9502ZPS6NGjacqUKQUnifKpceGOPdTCl6HOoygPpwHhgHBEZWtIh6L7+hSicSyfd704bHxtLR0\/eTLUetGNOGT36aq7cvUSJvnkOWfUz9U5h2fhqKys7HNHB3vJ5d\/a2tp8bwYMGkiUHwtB590tvsiEQ\/5SUL8woiqsSTpBVjJ2VZkQz1aYIO3Li9yLL75IAxoafK8q7snlnKmrsB6TqSo+Wc4Pn\/5evHgxrVixwrnoSTz8e21trfOf6pWwsrDoPNYKb7YsJCIe4aY9rDKr8UZV51GVpywjDtW9cdxEJMhKhnBEacrJSCtI+\/IqcX19Pb3W3k5XeQRit9h31tXR4cOHQ4NnIxzybX9qhvj2PR5F8SP8Q\/H\/93J1LqfNfqnWrFlD3\/\/+9\/uIUmgFlyKOqs6jKItII7IRh65QqoiwvxjZKKIEIdIKspIhHOWowXinGaR9eZV05E030fEvOlrPcCFPV9kKh+wrSs23GJmYCge\/Ly5\/YlHiTQIrV650bhOM8omqzqMsU1mFQx6KqncCl0tAgqxkCEeUppyMtIK0L68S33TTTfRePp+oEYfuZj+5jOr6B\/\/mNVUlj0jGjRtHfA1t1NNUIo8PPvhgqnx4lUU41J0R8gX2omGVa\/QRZMOGcCSjM48yl0Hal1e+Tdc4\/nv16lC35tqMOIS32r179xYWuOWdUKNGjfJdHFenskT6b7zxRuF+8CjrG8JRIm1VLDg6+RpJ9ctCNp4Sk7Z6PciGDeGwQp+JwEHalx8wnq4q964qMV3Et\/DpXJfz7+oUlJsbdg7rtx1XFQ6Rvrqo7scuyN+jrPMg8+0VV2QjDnXbnVemeEgK4WhK1dA2KoOOezpRdiJ+5zheOXy4sFsp7txKyR\/3J\/yUY5oKI45Sai7gd0XjE9G6jVzE77zzQr7MxWsnV5ANGyOOgCs+BdEFaV8mOMp9ctwkj2GG4amqcu2mEuWKus7D5CnijnTEodujLTJiOsoQIrBp0ybi059cKUuWLHGdv1TDi6Ex3xwmn1YtppL9GiWEIwoTTlYaaexE4loDgjVv5S3XaAMjjhKtg6eqghAO3ZY83d9kQVLnN+UrK+WDRn6VLN+Z0NvbSw0PPeTqzmHVj3\/sbPvjC3pum7eerh9ufrPbB+\/9iX7fiqmqEk0ulq9DOGJZLaFmKo11HuqIQ74c3qRm\/L4MRHzi8nl5lGDjSqAY4WDRELe0sWh0nz1LZ3p7Xd05VPfrR0NuvNHJIoTDpPazEUZ0IuzDiW\/Lw5N+Al1dXU7f4TelniQSoQqHDMJvxGECzc1JmbyXm10L+D1e02JuXwfi79964IeU7zhKTb9r83XnsGrCnfS\/75+EcPhVSIZ+lz9AMlTszBc1bVfqRiYcQVhOEMLhN2yUvwinT59OQ4cOdbIur1e079pEp9465nu4akD\/\/jRkyBAIRxCVn6I40nJNbIqqJPSicD8i+pLQE4sggUwJh8limbxji6cT+J8qHL\/d\/Dh92N3lWz0VX0xXYarKFxUCgAAIJIhAqMIhRgjDhg0j9kGzYMEC6ujocMXDjsiES2RdoFLWOExEQxaIjRs3OnPQuhHHgc2P0\/nuLow4EmToyCoIgEBwBEIVjuCy+WVMtruqZDEwWZzyW+Pg0cP7p05Q40+X+65xrBx3O31+rhNTVWEYAuIEARAoG4HECUcQ5zi8aJsIB2+t3TX\/Lnq3u8t1V9WIqhq6d\/HTzrZaTFWVzb6RMAiAQAgEEicc8ghC8JBHEupWW9XvjcxQNwIxFY6Pu7to\/+o5tLW764prOR+tqqFpq3fRxb9\/COEIwWgRJQiAQHkJhCocOseGXsX1W+OIApWpcHBeWDzeav81nf7zMerp7qJeIrq57ns0ccYCJ6viIB9GHFHUHNIAARCIikCowhFVIYJMx0Y4\/NINSjj8XJv45QO\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\/\/EA40FhAAARA4DKByITDxMW6n1v1KIWDD8Xx4ThxqhrCgSYDAiAAAhELRxDAi13jEGnbTFWp0zcQjiBqEHGAAAikgUBkI46gYBWzqwrCoaePxfGgrBLxgEC2CEQiHLyrib3fiqeUxdhSznFgxNHXuCEc2WrsKC0IBEUgdOFg0diyZUvhgJ7bveM2BfI6Oe61AA\/hgHDY2BnCggAI6AmEKhxuHTWLydGjR13PXZSzsrJ+jgN3lZfT+pA2CCSDQKjC4Xboz\/TcRTkQZlk4WDRwV3k5rA5pgkCyCJRNOEz9S0WNM6vCMXjwYEc0cFd51BaH9EAgeQQgHEqdZVU4\/vKXv9CAhgbfezxwV3nyGjlyDAJBE4BwQDici5x419tr7e2+NwfirvKgmyDiA4HkEYBwQDgctyo\/eeYZOp7P+1ow31V+\/ORJXDXrSwoBQCC9BCIRjo6ODiOCfi5HjCIpMVAWp6oYmc1d5dOmTcM95SXaGV4HgSQTCFU4kggmi8LxrQd+SO+fOkGPtT3ju8bx+PDR9E+XLuKe8iQaN\/IMAgERgHBgqoqE2\/dd8+\/yvav83sVP0+9bmyAcATVARAMCSSQA4YBwFISDr5v1u6v84t8\/hHAksaUjzyAQIAEIB4SjIByMwu+ucvi3CrD1ISoQSCgBCAeEo49w+NkxhMOPEH4HgfQTgHBAOCAc6W\/nKCEIBEoAwgHhKFk44Bgx0DaJyEAg9gQgHBCOkoQDjhFj38aRQRAInACEA8JRtHDAMWLg7RERgkAiCEA4IBxFCwccIyaijSOTIBA4AQgHhKNo4YBjxMDbIyIEgUQQgHBAOIoWjodmzzZyjDiyttZxjIgHBEAgHQQgHBCOooSDPeo+88wz9F4+7+uKfdSIEXT48GF41E1Hn4FSgABBOCAcRQkHY\/vkk0\/oJ93dvo4R5113HU24\/W564fmnIR7odEAgBQQgHBCOooSDPeoOGHgD\/Xbz476OEcdPa6C3D70Ex4gp6DBQBBBgAhAOCEdRwiE86hbrGBGHBtEBgUByCUA4IBwlCQfjs3WMiEODye0wkHMQwIhDYwNZvMhJjB5MmoRwcljMO3y3OQ4NmlBGGBCINwGMODDiKHnE4WfiskddHBr0o4XfQSD+BCAcEI7IhIO38O7fv59ea2832sK7e\/duZxcW\/8MDAiAQHwIQDghHZMLBqM92dtKF3l7fFlDRrx8NufFGmjBhAm3cuBHi4UsMAUAgOgIQDghHZMLBW3gP\/ayFznd3+Y44ht08nm657Z4+23ixEyu6jgEpgYAXAQgHhCMy4eAF9fdPnaDGny73PTT49IwFNGLc7YX7zcWi+pp8nmbwPnIiukREvyCilbW1tD2Xo7q6OrR2EACBCAhAOCAckQrH9cNvpV3z7\/I9NDjn+VdJLKqvW7eOftTcTMfyeRqoaRQfEdF4+MOKoLtAEiBwmQCEA8IRuXCYHBq8tqqmIByKCABoAAAJuklEQVRTpkyh+m3bfEcpPbkczZ07F20bBEAgZAIQDghH5MLByP0ODXIYMeI4e\/Ys9Xz2me+6yJ11dY4zRfXB2kjIvQiizxwBCAeEoyzCYdLSCsJhsRPr8JEjfbbw4pS6CWmEAQE7AhAOCEfshaOzs5Mu9vb6jjgG9O9PQ4YMKWzh7e3tpcn19UWtjWCUYteRIHS2CEA4IByxF46BoydS0+\/afNc41tw9g6pvGl3YwlvsKXWMUrLVCaK09gQgHBCO2AsHb+M1cd8u78SyPaUuLpoSolHMDi6MUuw7ILyRTAIQDghHIoTj6q8Nov2r59DW7q4rznE8WlVD01bvInknFlerzSn1afff75xQP3ToEA1oaPAd3ag7uDBKSWYHiFwXRwDCAeFIhHDw+Q+bnVg2p9TF2kg5RinFNVu8BQLlJZAJ4bhw4QI1NzfTwYMHHdpTp06llpYWqqiouII+3Kp7G2QpbtVtXLFzLkpNy\/SU+spxt9Pn5zqdgkc5Silv00fqIFA8gUwIx\/r16+nMmTOOWPDDIlJdXU1NTU0QjtamxIw4TMxcFRuTU+r3Ln7acW0SxSgFHn9NahFh4k4g9cJx\/PhxWrZsGW3YsIFGjhzp1Ifub6KiMOJIz4hDTG\/5rY1c\/PuHjnDY+NIqdpQiPP7ef\/\/9VFNTY9w\/wL28MSoEjIBA6oWDhYBHHDt27KDKykoHqZi6mj17Nk2cOLEP5mKE49NPP6X33nuPhg8fTtdcc00hvmKmWoKYouEO0+QpJn9e78SVg9\/aSFSjFNnjr0n9yGHYvbyt2NimweGDFKjTp0\/TL3\/5S5o+fXqm3eKnkUPqhWPfvn109OjRPmsaQjgmTZpEM2fO1AoHL5RyYxVPV1cXLV26lEZOW0zXf6Nvx8wdJgvOLbfcQjfccEPhnQt\/O0F\/\/Pcnte94Nepi3ovDO2nh8PH7XfTKpkdpV8\/5K3ZwzRlwHU1espX+8dJnhbr99Nz\/0MKdT\/nuxHrq3gbH4y\/bRM0d\/0oDBn5pK372cPo\/9hejA9bvBClQos2obck6Uwl\/oRQO6odtXFBAOBTh4K8DFojXX3\/9ijq6dPVX6bMR9xD\/r8lz1cVPqN+5E9Rb+Q3jdzjeYt5L2zvl5vB5z3m68Nc\/0v998Fe6quc88dVT\/YeNoa\/+82XX7Srv8y8\/S2d7zrt67x0y4Dq6bsqikur286+aCQ3n7x8ufuqkZfvOV869S1\/55G8m5o0wERDgmYw4PhAORTi4klg8+B8eEDAlwO5NGh56iNzuC8nt3k39+vUzjQ7hQMAhgBFHmQzBdo2jTNlEsikggJPjKahEFMGIQOpHHLa7qoyoIRAIgAAIZJhA6oWD69bmHEeGbQFFBwEQAAEjApkQDpuT40bUEAgEQAAEMkwgE8KR4fpF0UEABEAgcAIQjsCRIkIQAAEQSDcBCEe66xelAwEQAIHACUA4SkCKtZPL8ISbFhnlmDFj+rh5KQFzYl7lTRi1tbVXeCPgv7e2tjrlyAIXHQfe3djQ0OA4GxUPOxrN5XIFH3KJqWiPjKrl1HniToM9QDhKsFbs1roMT+fWpQSsiXxVdAbr1q3rIxzMZu\/evQURlW1G59Y\/kYWXMu3GQXeeKullVfMvRGPTpk2Fg3tqfafFHiAcRVovzod8CY4bBz86N\/VF4k3Ma+fOnaPGxkbq7u6mqqoqmjVrVkE4xG\/MRZwA1v0tMYX1yKgXh6x8XOg+oOR+YtCgQY6tpMEeIBxFtlqcSL8MzsthZJFoE\/UadxZ8YnzhwoXOPS+y40w39\/1uU1qJKriSWS8OHDSrHxeyDTAH9YoHwUY3xRlne4BwFFk7tl53i0wm9q\/xl+bixYvp\/Pnz1NHR4eQ3C\/P4asXoBNRteibNnaiOg\/gb28iRI0ccdGlc39A1Vnlq6p133rniioekiiqEo8iuGcJxGZyY133ssccKUzTqPG6RiBP1GoTDfQQqprF4uk5MZ7KoLlmyJHWL47LRqnf7pOlDAsJRZPcE4XAHJzoKeb6\/SMyJeQ3C4S4cukoUvNyucE5MxbtkVIiGvFkCwpH0Wg0g\/1jjcIeYxXUPXZmztMYhrMGm7tM6ZacTDTE6xxpHAJ1vkqPArqrLtacT0LTuHPKyV12HmaVdVV7CoWsrNgKTpH7C7eppLkOa7AFTVSVYJc5xfNkY5GmptJ9V8Jp6Ua8jTsu+fdNm4rU4Lk9LpXEdTHeOQ+WWFnuAcJi2CE04nBy\/DEV8SYldVbrTsiVgTsSrXl\/QaTgpbFoJbhzUtpLGnXdyPau89uzZ0+dQYNI9CUA4TFsEwoEACIAACDgEIBwwBBAAARAAASsCEA4rXAgMAiAAAiAA4YANgAAIgAAIWBGAcFjhQmAQAAEQAAEIB2wABEAABEDAigCEwwoXAqedgLptlMsbh62jvNXzjjvuKGzpTHs9oHzxJgDhiHf9IHcREhCnfufNm9fnbhGxP1\/eix9htgqOJOULgqJMH2mBgEoAwgGbAAEXL78yGBYPFpYdO3ZQZWVlpMxMTiRHmiEklnkCEI7MmwAAMAE\/YThx4gT179+f+LpXIRzqXevyiXk376+qLyPhgoLdjbObcXEnt\/Cq6pUGag4EykUAwlEu8kg3NgREJ88ZamlpccTB7+EOf\/ny5SSmr0Qcp06dckYlHAffCKi6DdcJB8cji44aN0YcfrWB36MmAOGImjjSix0B3UVDXpl0u29EvtTqO9\/5jrFwbNmypc+FRmr8EI7YmUzmMwThyLwJAICtcLh15PL0lLiD3GTEsXfv3j5rJxAO2GTcCUA44l5DyF\/oBGynqtzuXAhaOMRVqxhxhG4CSMCSAITDEhiCp5OA3\/0Q8jTU2LFjqaGhgdTtsRCOdNoGSnUlAQgHrAIEDLfjHjx40FmLGDRoEDU2NjqH8Xg3lHhM1jjUhW+dYKlTZxhxwETjRgDCEbcaQX7KRsDvAKDYIssZ9NtVxVt2OYy88C0EgLfcit1YJsLhthhfNlBIOPMEIByZNwEAkAmotxnyb24uR9QzFuqJc35Xvf1PnNcQ01wmwiHHEwf3J7AYEIBwwAZAAARAAASsCEA4rHAhMAiAAAiAAIQDNgACIAACIGBFAMJhhQuBQQAEQAAEIBywARAAARAAASsCEA4rXAgMAiAAAiAA4YANgAAIgAAIWBGAcFjhQmAQAAEQAAEIB2wABEAABEDAigCEwwoXAoMACIAACEA4YAMgAAIgAAJWBCAcVrgQGARAAARAAMIBGwABEAABELAiAOGwwoXAIAACIAACEA7YAAiAAAiAgBUBCIcVLgQGARAAARCAcMAGQAAEQAAErAj8P9lrhkzD8QXgAAAAAElFTkSuQmCC","height":192,"width":318}}
%---
%[output:04cb978a]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.060537\n","truncated":false}}
%---
%[output:97e30ae9]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAY4AAADwCAYAAAAXW4N5AAAAAXNSR0IArs4c6QAAGx1JREFUeF7tnU1oXcXfgKfLuLy1CLFoEYI7i\/wXDRHRhe8yCm+haXXzhghBaCzYfHbhoos2SVMh7SqLkJX5ELIxy7o1mIUfcacBqX9iQGpCcWGX92WOTpx7cj5zz8f85jwXgjU5d+Y3z2\/uPHdmzseZdrvdVrwgAAEIQAACGQmcQRwZSXEYBCAAAQgEBBAHHQECEIAABHIRQBy5cHEwBCAAAQggDvoABCAAAQjkIoA4cuHiYAhAAAIQQBz0AQhAAAIQyEUAceTCxcEQgAAEIIA46AMQgAAEIJCLAOLIhYuDIQABCEAAcdAHIAABCEAgFwHEkQsXB0MAAhCAAOKgD0AAAhCAQC4CiCMXLg6GAAQgAAHEQR+AAAQgAIFcBBBHLlwcDAEIQAACiIM+AAEIQAACuQggjly4OFgTePbsmZqenlZbW1uJQN5++231888\/B8esrKyovr6+ygHu7e2p4eHhQmP45ptv1NrampqdnVU9PT1qY2NDzczMqMHBwePfVd7QgivUbXr8+LGampoquGSK84EA4vAhixW3ocniiJKEb+KYm5tTS0tLanR0FHFU\/NmSUh3ikJIph+Ms41u9q81FHK5mhriqJIA4qqTtaV1x4oj6vf1t9sKFC8ESj35dvHhRLS8vq8PDw2Bp6eDgIPj96uqq6u\/vPyanl4nef\/\/94\/9P+1acFsNbb73VUd7du3fV0NBQZKZM7PYf9fH6ZZaqJicn1fXr19Xu7m7w+3B84dlab29vpmW8cN32+4zMDMNWqxXUbddl2mWOtdtgGMfNJM3fj46O1MjIyHHbwvXZUn3vvffUhx9+GFRjYj179mzH+5NYe\/pR8aZZiMObVNbXkNOIIypaPRA9efLkWBq2UPRgGDXo6WOS9haSxBFHLCwrc1yaOKLi1+81A2R44I0avKNiiqrXZqP\/bQZ0O\/Zw27\/77rtjUdv1mIH9\/PnzkXtXukw96NtCN++PEljW3GaVZn09m5rjCCAO+kbXBE4jjrgBxwyy9szCHrh0sGaj3f6GHDfYp4kj6tt00iwmaanKloQdmxHbgwcPTuwdmHbGyS9q1mALyPCK2pcwsZr2hI+xy7bbnHScPUsIl2+L3XC182jqMDnRs0pmHV1\/\/GopAHHUgt2vSk8jDnugNIOLLRN7cNSDkH7ZS1RhgnGDfZI4woN1lk3hJHEkLd18+umn6vbt27FnoiV9+w7POKIGW8PQxBA1CwnP2OKYhTkkzZTsmc+jR4+CGY3NwZZE1JIY4pA5FiAOmXlzKurTiMMetMKDnl6WCovj119\/jVxmMSBOI47we7oVR1hEtmTCex\/hBCaJI+kstqjB2BZtnBzD9dsDeJiDPfjHLUPp\/SkjDrvOqL4RNYtyqkMTTCoBxJGKiAPSCFQhDjPjCH+rP01scYIoUxz2jKPbb9n2zMEepO2lI81Fn1KbVJe9jGRzTZpxxC0J6vqiZmOII62Hyvw74pCZN6eirkIc9uZs1GbzafY4qpxx6IsFzR6HPUinXQMStZ9hD9Jxy0L2EpKewcXtZ0QtEybtcdiiCh+HOJz6WJYaDOIoFW8zCq9CHPqU3Lizi057VlU34rCXyMxpxUlLVVoc+\/v7kWcm6bKyfJOP6k3hGYXNKNy+8KnMdnlRm+Pm77qOl19+OXKPKeokB5aq\/P\/cIw7\/c1x6C6sSh\/1N2zQq7TYfaddx2LfUyLJUFd5v0ANuVnHo25NEbTQnScO0M2rQT9okj5NR1H5FWDDhGE094feG92WYcZT+UXOmApHiCH+I0j544Q6fNtg4kx0CgUBOAmlLXzmL43AIRBIQJw4jgYWFheCKYi2R8fHx2Ktvw8drCvqbpT6H3Nykjr4BAekEspyyK72NxO8OAXHi0B8Q\/QovMYR\/ZxDrb2Db29sdktAy0adHzs\/P13LHVnfSTyS+EEja2\/CljbTDHQKixGHWlwcGBjruJxS+zXUaXsSRRoi\/QwACEIgnIEocZtNOzzbCN77T37j0RUjmBm9JSdezkPX19czH04EgAAEIQOBfAo0Th9lYT9pQ16dN6h9eEIAABOoioG86qX9cfDVKHEYaWa+mdTFhxAQBCDSDwKVLl9S9e\/eclIcocXSzx5FFGro7muNev\/KJ+uvod\/XTV58HyXvxxReb0VtTWrmzs6MWFxdhksAJRukfFRglMzJ80i41SCddzhGixKER5D2rypZBliQYcbwx+vfZW18vTSVe1VtOWtwtVS\/hbW5uqsuXLzv5TcgFcjBKzwKMkhllWVJPp1zeEeLEUcR1HEk4EUd5nY2SIQCBbAQQRzZOuY5KunI8fKpt3P2NdIVRMxDEkSsVHAwBCJRAAHGUALXMIhFHmXQpGwIQyEIAcWSh5NAxiMOhZBAKBBpKAHEIS3yUOG7cuKH0qXEun1ctDDPhQgACCQQQh7DuESUO0wSXz6sWhplwIQABxOFPH4gSh31NR5ZTev2hQUsgAIE6CDDjqIN6F3VGiYNrOroAylshAIHcBBBHbmT1vgFx1Muf2iEAgX\/vYOHqCoe4CwDL7lSIo2zClA8BCKQRYMaRRsixvyMOxxJCOBBoIAHEISzpiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEISypiENYwggXAh4SQBzCkoo4hCWMcCHgIQHEkTOpz549U9PT02prayt45+DgoJqdnVU9PT2pJe3t7ak7d+6o+\/fvq1ardXy8SYJdwMWLF9Xy8nLHcfrviCMVMwdAAAIlE0AcOQHPzc2pg4ODQBb6pSXS29urpqamEkvS0hgeHlbnzp07IYSNjQ21vb2dSUCII2fCOBwCECicAOLIgVQP\/pOTk2p+fl719fUF74z6XbhILYaZmRn15ptvqj\/\/\/POEOLSM9CtNPsw4ciSLQyEAgdIIII4caDUsPcjbS0hm6eratWuqv7\/\/RGlHR0fq5s2b6tatW+rw8DD2\/QMDA2poaCg1GmYcqYg4AAIQKJkA4sgBOGpJyYgjy8AfJR4jlqdPn6rd3d0gmrj9DXvG8eo7H6jnWi+o77\/4TL0x+veM5eulKbW6uhopsBzN5FAIQAACsQT29\/fVzs6OmpiYcHa8OdNut9vd5lAPziMjI8HAnGczO2rJKbwX0a04zN7H2NjY8YxDC2p9fT1xc1zH9vwrr6k\/fvkRcXTbQXg\/BCCQmcDi4qLSP\/rl6hfVQsRhiJi9BvP\/eSVSxowjKltGdFevXj2xfGWmiK9f+SR4KzOOzP2dAyEAgQII6BnH5uZmII9GiMNmFpbI6Oho6ub0afY47Dqj3h+Vx6RZDHscBfR8ioAABLoi0Pg9Dr3ZvbS0dAwxSSCnPavKFB4ljrh9D720ps+yCm+4I46u+jtvhgAECiDQOHHY+x2an74GY2VlJTi91sBIksdpr+PQdSVJwl6WsusIX1iIOAro9RQBAQh0RaAR4gjLQhOLW5tL2pjW70u7cjxpOSrub+H4kvZeEEdX\/Z03QwACBRBolDiiNpvDDNPEUQDzropAHF3h480QgEABBBohjgI4OVME4nAmFQQCgcYSaIQ47Ku3za1C7Iy7PsuwY0Ucjf2s0nAIOEMAcSilEIcz\/ZFAIAABAQS8FUd4EzstF3fv3s10r6i0csr+OzOOsglTPgQgkEbAW3HYDU9bqkqD5NLfEYdL2SAWCDSTQCPE4VNqEYdP2aQtEJBJAHEIyxviEJYwwoWAhwS8FYe5qO6ll14KHr50\/fr149uWR+Ux6VbmLuUdcbiUDWKBQDMJeCsOX9OJOHzNLO2CgBwCiENOroJIEYewhBEuBDwkgDiEJRVxCEsY4ULAQwLeiiPqxoZJ+WOPw8PeTZMgAIFSCHgrjlJoOVAoMw4HkkAIEGg4AcQhrAMgDmEJI1wIeEjAW3FwOq6HvZUmQQACThDwVhxO0C0hCGYcJUClSAhAIBcBxJELV\/0HI476c0AEEGg6AcQhrAcgDmEJI1wIeEigUeKIOkU36fneLuYbcbiYFWKCQLMINEYcpqHh527ohzg9fPhQraysqKinA7rWHRCHaxkhHgg0j0AjxGEe6tTb26umpqZOZHlubk4dHByo2dlZ1dPT43QvQBxOp4fgINAIAo0Qh1miunr1auRT\/nh0bCP6Oo2EAAQKItAIcTDjKKi3UAwEIAAB62arq6urqr+\/3zkmZ9rtdruIqPb29tTw8LAaGxvrmHWwx1EEXcqAAASaRMDbGQc3OWxSN6atEIBAlQS8FUeVEMN1Gajm93mmc3qj\/sKFC5F7Mbo8NsfrzCx1QwAC9jiUZ2yrklxhS1VVBW2WxBYWFoK1Pz3Qj4+PZzrdV0tjaWlJhU8ZtmNHHFVlknogAIE4Ao2ZcaQtXRX1PA49+OuXfdpv1O\/shJjYnjx5os6dO6fizv5ixsEHGQIQcIFAY8RhX6vx5ZdfqsePHweDu54hTE5Oqvn5+a4vADRnbw0MDHQsNWnIa2trsdeJ6A16Hc\/HH3+spqenVfj9zDhc+KgQAwQgYAg0Qhzh6zjCA7kZuKMuDszTVUw9uhz7FDVdnxbX8vKyarVasUXGiQdx5MkCx0IAAmUTaKQ49Czjzp076v79+8FAHv7\/00KvUhyvvvOBeq71gvr+i8\/UG6N\/L499vTSlXN2sOi1T3gcBCLhFYH9\/X+3s7KiJiQlnx5tCNsfD3+T1AH\/z5k1169atYHlKojh0V3r+ldfUH7\/8iDjc+lwRDQS8JrC4uKj0j365+kW1EHHoBoZvK2Kf9qr\/tr293fW9qk67x2F6WZ6lqtevfBK8jRmH159RGgcB5wjoGcfm5mYgD+\/FoenbG+R6kB4ZGVG7u7uqqDOqTB36v3nOqjqNOOzlKZaqnPtsERAEvCbQiD2OKjPYzXUceWYciKPKrFIXBCBgE0AcJfSHpCvHk07\/RRwlJIMiIQCBwgk0Shw8AbDw\/kOBEIBAAwk0Rhw8AbCBvZsmQwACpRBohDh4HkcpfYdCIQCBhhJohDh4AmBDezfNhgAESiHQCHEw4yil71AoBCDQUAKNEIfOLU8AbGgPp9kQgEDhBLwVR9pt1MMki7wIsPAsWQXyPI4y6VI2BCCQhYC34sjSeInHIA6JWSNmCPhFAHEIyyfiEJYwwoWAhwQaJQ6zz3FwcHCcyt7e3kyPdXUl94jDlUwQBwSaS6Ax4ki6AHBmZsbZuzyGuybiaO6HlZZDwBUCjRAHp+O60t2IAwIQ8IFAI8TBBYA+dFXaAAEIuEKgEeJgxuFKdyMOCEDABwKNEIdOFHscPnRX2gABCLhAoDHi0LA5q8qFLkcMEICAdAKNEof0ZNkzJ54A6EM2aQMEZBJohDjMHse1a9dUf3+\/zEz9EzWn44pOH8FDwAsCjRBH2llVkjKJOCRli1gh4CeBRogjy7O8paQXcUjJFHFCwF8CjRCH2RifnJxU8\/Pzqq+vT2xGEYfY1BE4BLwh0AhxZLnFOrdV96ZP0xAIQKBkAo0QR8kMKy2eGUeluKkMAhCIIIA4hHULxCEsYYQLAQ8JeC+OjY0Npe9+a16rq6uiT8lFHB5+CmkSBIQR8FocWhoPHz48ft5G3HPHJeUMcUjKFrFCwE8C3ooj7hRcLZPt7W01Ozurenp6xGUVcYhLGQFDwDsC3ooj7qI\/3eC5uTm1vLysWq1W7oQaIW1tbQXvHRwcTJWQgRy3XBb+uz4u7iwvxJE7ZbwBAhAomEAjxTE+Pn7qx8Vq6ehHz+oZi35NT08r\/fjZqampyNSY5bGFhYVgb0UDD9efZxaEOAr+BFAcBCCQmwDiyIFMSyB8EWHU7+witWj0yxZL+HdRx8SFhThyJIxDIQCBUgggjhxYo5a5km6gGLfPostZW1vrmLUMDAyooaGh1GgQRyoiDoAABEomgDhyAI5aUkq6D5bZZ9GzDfuuvLaAdPU3b95UT58+Vbu7u0E0SVexI44cCeNQCECgFALei8MMxmn0stxypAxxHB4equHhYTU2NnY849D1rK+vR27gm4S9+s4H6rnWC+r7Lz5T9rM5pF+nkpYn\/g4BCNRLYH9\/X+3s7KiJiQnl6nhzpt1ut+vF9G\/tZYgj6syupNvA22dgPf\/Ka+qPX35EHK50EOKAQAMILC4uKv2jX4gjQ8LL2OOIupYkafnLiOP1K58EETPjyJA4DoEABAojoGccm5ubgTwQRwasZZxVFSWjuL0RHSJ7HBkSxSEQgECpBLzd4yiLWtHXcUQtS9l1hGckiKOszFIuBCCQlQDiyErqn+PSrhyPmkGkXTkefl5I0tXoaeK4ceOGunTpkjp\/\/nzwwwsCEIBA0QQQR9FESy4vTRymei2Pe\/fuIY+S80HxEGgiAcQhLOtp4tCb5n8d\/a5++upzZzeuhCEnXAhAIEQAcQjrEmni4JoOYQklXAgIJIA4hCUNcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCUVcQhLGOFCwEMCiENYUhGHsIQRLgQ8JIA4hCU1jzhu3LihLl26pM6fPx\/88IIABCBQBAHEUQTFCsvIIw4TlpbHvXv3kEeFeaIqCPhMAHE4kN1nz56p6elptbW1FUQzODioZmdnVU9Pz4no8ojj9SufqL+Oflc\/ffW5Wl1dVf39\/Q60lhAgAAHpBBCHAxmcm5tTBwcHgSz0S0ukt7dXTU1NdSWON0bngvd\/vTSFOBzIMyFAwBcCiKPmTO7t7anJyUk1Pz+v+vr6gmiifmfCzDPjsMXBfkfNiaZ6CHhEAHHUnEydAD3jWF5eVq1WK4jGLF1du3btxPLSacVhmun7fsf+\/r7a3NxUly9fZk8npm\/DKP1DD6NkRogjvQ+VesTGxoba3t7u2NMw4hgYGFBDQ0Md9ZuEvfrOB+q51gvq+y8+U1n+\/dJ\/\/ico57\/fPlJm9lFqw2oq\/LffflMTExNet7FbtDBKJwijZEaGj6t7p2fa7XY7Pc1yj8grDv1N6H\/\/77r645cf5TaayCEAAfEEXF69QByhGYfubVoe+ocXBCAAgboIuHx9mPfiyLvHUVcnoV4IQAACUgh4L468Z1VJSRxxQgACEKiLgPfi0GDzXMdRVyKoFwIQgIAUAo0QR54rx6UkjjghAAEI1EWgEeKoCy71QgACEPCRAOLwMau0CQIQgECJBBBHiXApGgIQgICPBBDHP1llHyS9e+sz1IaHh4MbRupX0l2G00vz\/4ike6L53\/r4FuqTVZaWloIDLl682HE7oCZzMW2XMBYhjn+yxZlXyR9ZI42FhYXj+3vZzKJuUd\/kQcB8+L\/99lu1srJyfINNmEwHCMxjDehDJ3uEhLEIccTcLZdvi50dOurWLTCK14Dmtb6+Hhxg35m5yeLQF+OOj493iJQ+1Nkjjo6O1MjISPDIB\/N8HxcZIQ6lFFeXn244c7FDn64lxb7L9Cf94dffHhHH33yjvnwUS15+aYhDUA7z3ghRUNNKDdV8q7ZvWV9qhQIKtz\/4Z8+ePfEsGAFNKC1ELVH9unDhgpqZmQn+zR5H8lKVXgJ2cTmPGUfMN6GkW6+X9skSVLDrzwuoC6UZHPVsgxlZZxbMpvjdu3ePH2egf6f7El8+olnp346OjkY+rbSuPq7rRRyII3f\/M9KwB4DchXj4hvCSJ+I4ORjq39iPbDYztKtXr554No6HXSS1SVE89Mz+4cOHTp1kgTjY40jtzPYBSCMel32aafgoJPv3PePC4mBm39lTpCybIw7OqsosDpanMqMKDmTG0clL95+1tbWOp3FGbQbno+zX0YhDWD4lnDtdJ9Ko6zjqjEdC3YijM0tRswv2ODoZsVQl4ZNtxSjhas06kSYtw7j6XOQ6eTHjiKYf\/pxxVtVJTkYeu7u7wR9dZMRSVd2jC\/VDAAIQEEYAcQhLGOFCAAIQqJsA4qg7A9QPAQhAQBgBxCEsYYQLAQhAoG4CiKPuDFA\/BCAAAWEEEIewhBEuBCAAgboJII66M0D9zhHQF2GZm\/DFBadPkfzoo4\/U7du3nboVhHMwCchLAojDy7TSqCIJcBfgImlSlg8EEIcPWaQNpRJAHKXipXCBBBCHwKQRcrUE4sRhP9FOP3tDP7nt3XffVT\/88IPa2toKgjTPZX\/w4EHic7bDy2Mu3kq7WurU5jIBxOFydojNCQJ5xKFvE2FuwWLu73VwcKDM3XHNLTd0w+znbmvRmGeTm1tO6EeH2rcgdwIGQUCA53HQByCQTiCPOOzBPkoSuja7vMPDQzU8PKzGxsY6nkfBnYjT88IR9RFgxlEfe2oWQiCPOOwHEmURx6NHjyIf0sMDjoR0joaGiTgamnianZ1A2eJIOvWXB0BlzxNHVkcAcVTHmpqEEihbHOvr6zxzW2jfaGrYiKOpmafdmQmUKQ6zx7GwsKD0\/oh58eCszOnhwBoIII4aoFOlLAJliqPVagXP4rbPqorbG5FFjWh9JoA4fM4ubSuEQNni0EFyHUchqaKQigggjopAUw0EIAABXwggDl8ySTsgAAEIVEQAcVQEmmogAAEI+EIAcfiSSdoBAQhAoCICiKMi0FQDAQhAwBcCiMOXTNIOCEAAAhURQBwVgaYaCEAAAr4QQBy+ZJJ2QAACEKiIAOKoCDTVQAACEPCFAOLwJZO0AwIQgEBFBBBHRaCpBgIQgIAvBBCHL5mkHRCAAAQqIoA4KgJNNRCAAAR8IYA4fMkk7YAABCBQEQHEURFoqoEABCDgCwHE4UsmaQcEIACBigggjopAUw0EIAABXwj8P8a3svOy\/auoAAAAAElFTkSuQmCC","height":192,"width":318}}
%---
