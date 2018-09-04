% Code to analyze extracellular measures for 
% Figures 2-3,6-8 of Haley, Hampton, Marder (2018)

%% Load Data

clear
directory = '/Volumes/HardDrive/';
ganglia = {'STG','CG'};
exp.STG = {'877_093','877_101','877_121','877_127','877_141','887_049',...
    '887_069','887_097','887_105','887_137','887_145','897_037'};
% '887_005','887_141','897_005'
units.STG = 'PD';
exp.CG = {'887_011'};
% '877_149 CG1 and CG2, '887_005'
units.CG = {'CG3L'};

for i = 1:length(ganglia)
    ganglion = ganglia{i};
    for j = 1:length(exp.(ganglion))
        experimentName = exp.(ganglion){j};
        notebook = experimentName(1:3);
        data.(ganglion).(['prep_',experimentName]) = ...
            load([directory,notebook,'/',experimentName,'/Spike2 Analysis/data.mat']);
        order.(ganglion){j,1} = data.(ganglion).(['prep_',experimentName]).info.order;
    end
    numPrep.(ganglion) = length(exp.(ganglion)); % number of preps
end

%% Compute Means for 10s Bins of last 8 mins

binWidth = 10; % bin size (s)
window = 8*60; % window for analysis (s)
numBin = window/binWidth; % number of bins

measures = {'hz','spikes','duty'};

for g = 1:length(ganglia)
    ganglion = ganglia{g};
    
    for i = 1:numPrep.(ganglion)
        prep = ['prep_',exp.(ganglion){i}];
        
        if strcmp(order.(ganglion){i},'AB')
            sorted = [6:-1:1,6:12]; %order of conditions for AB protocol
        else
            sorted = [12:-1:7,1:7]; %order of conditions for BA protocol
        end
        
        for j = 1:length(sorted)
            condition = ['condition',num2str(sorted(j),'%02d')];
            fileName = data.(ganglion).(prep).(condition).fileName;
            f = find(strcmp(data.(ganglion).(prep).info.fileOrder,fileName));
            
            for k = 1:length(units)
                if g == 1
                    unit = units.STG;
                else
                    unit = units.CG{k};
                end
                
                for l = 1:length(measures)
                    measure = measures{l};
                    
                    % grab time and measure data
                    eventTime = data.(ganglion).(prep).(condition).(unit).tstart;
                    eventData = data.(ganglion).(prep).(condition).(unit).(measure);
                    start = min(find(eventTime > data.(ganglion).(prep).info.fileLength(f) - ...
                        data.(ganglion).(prep).info.sampleFreq*window)); % last 8 minutes only
                    eventTime = eventTime(start:end);
                    eventTime = eventTime - min(eventTime);
                    eventData = eventData(start:end);
                    
                    % compute means for bins
                    for m = 1:numBin
                        include = find(eventTime >= binWidth*(m-1) & eventTime < binWidth*m);
                        if ~isempty(include)
                            violin.([ganglion,'_',measure])(numBin*(i-1)+m,j) = ...
                                nanmean(eventData(include));
                        end
                        if isempty(include) || isnan(nanmean(eventData(include)))
                            violin.([ganglion,'_',measure])(numBin*(i-1)+m,j) = 0;
                        end
                    end
                end
            end
        end
    end
end

%% Make Violin Plots

measures = {'STG_hz','STG_spikes','STG_duty',...
    'CG_hz','CG_spikes','CG_duty'};

% limits = [-60,-20;-60,-20;0,30;0,12;0,9;0,20];
% labels = {'PD Minimum V_m (mV)','LP Minimum V_m (mV)',...
%     'PD Spike Amplitude (mV)','LP Spike Amplitude (mV)',...
%     'PD Burst Frequency (Hz)','LP Firing Rate (Hz)'};

for i = 1:length(measures)
    numPrep = size(violin.(measures{i}),1)/numBin;
    violinPlots(violin.(measures{i}));
    set(gcf,'Position',[1420 175 500 300]);
%     ylim(limits(i,:))
%     ylabel(labels{i})
    ax = gca;
    text(ax.XLim(2)*0.9,ax.YLim(1)+diff(ax.YLim)*0.95,['n = ',num2str(numPrep)],...
        'VerticalAlignment','top','HorizontalAlignment','right','FontSize',12);
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    set(gcf,'Renderer','painters')
    saveas(gcf,['/Volumes/HardDrive/Haley Hampton Marder 2018/Figures/Violin/',measures{i},'.pdf']);
end

%% Export csvs for statistical analysis in R

pH_vars = {'pH82_1' 'pH59' 'pH64' 'pH70' 'pH76' 'pH82_2' 'pH82_3' 'pH90'...
    'pH96' 'pH101' 'pH106' 'pH110' 'pH82_4'};
path = '/Volumes/HardDrive/Haley Hampton Marder 2018/Data/';

for i = 1:length(measures)
    for j = 1:numPrep
        output.(measures{i})(j,:) = mean(violin.(measures{i})(numBin*(j-1)+1:numBin*j,:));
        writetable(array2table(output.(measures{i}),'VariableNames',pH_vars),[path,measures{i},'.csv']);

    end
end

%% Save data

data.violin = violin;
save('/Volumes/HardDrive/Haley Hampton Marder 2018/Data Sets/extracellularData.mat','-struct','data');