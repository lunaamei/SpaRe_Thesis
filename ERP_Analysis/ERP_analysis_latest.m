cd /Users/lunameidoering/Uni/THESIS/feelSpacedata/
%folder to save matlab steps
savepath = '/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/Plots';
addpath('/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/Plots');
% adding MatLab scripts used in Debbie's initial script
% (eeg_preprocessing_spare.m)

addpath('/Users/lunameidoering/Uni/THESIS/MATLAB/eeglab2023.1');
addpath('/Users/lunameidoering/Uni/THESIS/MATLAB/eeglab2023.1/plugins/xdfimport1.18/xdf');

% Opening eeglab
eeglab;


%%
data_files = '/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/data';

subject_id = 4;
%% Automatic cleaning
cd(data_files);
EEG_automa = pop_loadset('/Users/lunameidoering/Uni/THESIS/feelSpacedata/piloting/data/5_3_interpolation.set');
EEG_automa = pop_epoch(EEG_automa, {}, [-0.25 0.8]);
EEG_automa = eeg_checkset(EEG_automa); %fixes data if something went wrong
currElec = 'Oz';
el_idx = find(strcmp({EEG_automa.chanlocs.labels}, currElec) == 1); %find the index of electrode
EEG_automa.mean = mean(EEG_automa.data(:,:,:), 3);
EEG_automa_avg   = EEG_automa.mean(el_idx, :); 

%% Convert the structure to a table
event_table = struct2table(EEG_automa.event); 
% convert columns from char to double
event_table.in_nodeRadius = str2double(event_table.in_nodeRadius);
event_table.closest_to_nodeCentroid= str2double(event_table.closest_to_nodeCentroid);
event_table.time_diff_normalized = str2double(event_table.time_diff_normalized);
event_table.node_1st_half = str2double(event_table.node_1st_half);
event_table.num_neighbours = str2double(event_table.num_neighbours);
%% For method 3

% Define the category names and ranges
categoryNames = {'time_diff1/5', 'time_diff2/5', 'time_diff3/5', 'time_diff4/5','time_diff5/5'};
edges = [0 0.2 0.4 0.6 0.8 1];


% add new column which categorizes time_diff values into quarters
event_table.time_diff_type = discretize(event_table.time_diff_normalized,edges,'categorical',categoryNames);
event_table.time_diff_type =  string(event_table.time_diff_type);


EEG_automa.event = table2struct(event_table);


%% calc grouped averages for temporal distance variable

for cat_idx = 1:length(categoryNames) %for each category

    grouped_idx{cat_idx} = find(strcmp(string({EEG_automa.event.time_diff_type}),categoryNames{cat_idx}) == 1); %creates cell array with indices sorted by category for each subject
    grouped_epochs{cat_idx} = cell2mat({EEG_automa.event(grouped_idx{cat_idx}).epoch}); % finds indices in epoched data

    grouped_means{cat_idx} = mean(EEG_automa.data(:,:,grouped_epochs{cat_idx}), 3); %calculates means
    grouped_avg{cat_idx} = grouped_means{cat_idx}(el_idx, :); %filter electrode

end


%% Method 1 - Node vs not node

node_idx = find([EEG_automa.event.in_nodeRadius] == 1);
node_epochs = cell2mat({EEG_automa.event(node_idx).epoch});
node_mean = mean(EEG_automa.data(:,:,node_epochs), 3); 
node_avg = node_mean(el_idx, :); %filter electrode

edge_idx = find([EEG_automa.event.in_nodeRadius] == 0);
edge_epochs = cell2mat({EEG_automa.event(edge_idx).epoch});
edge_mean = mean(EEG_automa.data(:,:,edge_epochs), 3); 
edge_avg = edge_mean(el_idx, :); %filter electrode

figure;
hold on;

plot(EEG_automa.times, node_avg, 'Color',"#0072BD", 'LineWidth', 1.2)
plot(EEG_automa.times, edge_avg, 'Color', "#D95319", 'LineWidth', 1.2) 


xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot3 ERP at %s - Method 1',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('Within Node Radius','Not Within Node Radius','FontSize',20)
set(gca,'fontname','arial')

%% with difference plot
figure;

% Upper plot
subplot(4, 1, [1 3]);

hold on;
plot(EEG_automa.times, node_avg, 'Color',"#0072BD", 'LineWidth', 1.2)
plot(EEG_automa.times, edge_avg, 'Color', "#D95319", 'LineWidth', 1.2)
xlim([-250 800]);
ylim([-15 20]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot3 ERP at %s - Method 1',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('Within Node Radius','Not Within Node Radius','FontSize',20)
set(gca,'fontname','arial')

% Lower plot (difference curve)
subplot(4, 1, 4); 
hold on;
plot(EEG_automa.times, node_avg - edge_avg, 'Color', 'r', 'LineWidth', 1.2)
xlim([-250 800]);
ylim([-10 10]);
line([0, 0], ylim, 'Color', 'k');
line(xlim, [0, 0], 'Color', 'k');
xlabel('time [ms]');
ylabel('Difference (µV)');
title('Difference Curve', 'FontSize', 20);
set(gca, 'fontname', 'arial');

%% Plot Node 1st half vs other

hnode_idx = find([EEG_automa.event.node_1st_half] == 1);
hnode_epochs = cell2mat({EEG_automa.event(hnode_idx).epoch});
hnode_mean = mean(EEG_automa.data(:,:,hnode_epochs), 3); 
hnode_avg = hnode_mean(el_idx, :); %filter electrode

hedge_idx = find([EEG_automa.event.node_1st_half] == 0);
hedge_epochs = cell2mat({EEG_automa.event(hedge_idx).epoch});
hedge_mean = mean(EEG_automa.data(:,:,hedge_epochs), 3); 
hedge_avg = hedge_mean(el_idx, :); %filter electrode

figure;
hold on;

plot(EEG_automa.times, hnode_avg, 'Color',"#0072BD", 'LineWidth', 1.2)
plot(EEG_automa.times, hedge_avg, 'Color', "#D95319", 'LineWidth', 1.2)


xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot3 ERP at %s - Nethod 2',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('In First Half of Node Radius','Not in First Half of Node Radius')
set(gca,'fontname','arial')

%% with difference curve

figure;

% Upper plot
subplot(4, 1, [1 3]);

hold on;
plot(EEG_automa.times, hnode_avg, 'Color',"#0072BD", 'LineWidth', 1.2)
plot(EEG_automa.times, hedge_avg, 'Color', "#D95319", 'LineWidth', 1.2)
xlim([-250 800]);
ylim([-15 20]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot3 ERP at %s - Method 2',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('In First Half of Node Radius','Not in First Half of Node Radius','FontSize',20)
set(gca,'fontname','arial')

% Lower plot (difference curve)
subplot(4, 1, 4); 
hold on;
plot(EEG_automa.times, hnode_avg - hedge_avg, 'Color', 'r', 'LineWidth', 1.2)
xlim([-250 800]);
ylim([-10 10]);
line([0, 0], ylim, 'Color', 'k');
line(xlim, [0, 0], 'Color', 'k');
xlabel('time [ms]');
ylabel('Difference (µV)');
title('Difference Curve', 'FontSize', 20);
set(gca, 'fontname', 'arial');


%% Plot Comparison of Methods

figure;
hold on;

plot(EEG_automa.times, node_avg, 'Color', "#D95319", 'LineWidth', 1) % within node radius
plot(EEG_automa.times, hnode_avg, 'Color',"#0072BD", 'LineWidth', 1) %in 1st half of node radius
plot(EEG_automa.times, grouped_avg{5}, 'LineWidth', 1,'Color',"#7E2F8E"); % first quantile of edge
plot(EEG_automa.times, grouped_avg{1}, 'LineWidth', 1,'Color',"#EDB120"); % last quantile of edge


xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot 3 ERP at %s - Method Comparison',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('Within Node Radius','In first Half of Node Radius','Time Segment 5','Time Segment 1','FontSize',20)
set(gca,'fontname','arial')
saveas(gcf,sprintf('%s/pilot%s_methodcomparison_ERPs.jpg',savepath, subject_id),'jpg');

%% Plot num neighbors

%  group data by number of neighbors
for n = 1:4 % there can be 1-4 neighbors

    nb_idx{n} = find([EEG_automa.event.num_neighbours] == n & [EEG_automa.event.node_1st_half] == 1);
    nb_epochs{n} = cell2mat({EEG_automa.event(nb_idx{n}).epoch}); % finds indices in epoched data
    nb_means{n} = mean(EEG_automa.data(:,:,nb_epochs{n}), 3); %calculates means
    nb_avg{n} = nb_means{n}(el_idx, :); %filter electrode

end

% Define category names and corresponding colors
cNames = {'1 Neighboring Node', '2 Neighboring Nodes','3 Neighboring Nodes','4 Neighboring Nodes'};
cColors = {"#D95319", "#4DBEEE","#77AC30","#7E2F8E"};

figure;
hold on;

for catIdx = 1:length(cNames)
    currentCategory = cNames{catIdx};
    
    % Plot ERP for the current category
    plot(EEG_automa.times, nb_avg{catIdx},'Linewidth',0.7,'Color',cColors{catIdx},'DisplayName', currentCategory);
end

xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot 4 Event-Related Potentials at %s by Number of Neighboring Nodes (within 1st half)' ,currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend(cNames,'FontSize',20);
set(gca,'fontname','arial');



%% Create Means for events grouped by event type x node 1st half

num_cats = 5;
cat_names = {'Other_Buildings','Global_Landmark','TaskBuilding_Public','TaskBuilding_Residential','Background'};

for cat_idx = 1:length(cat_names) %for each category

    type_idx{1,cat_idx} = find([EEG_automa.event.node_1st_half] == 1 & strcmp(string({EEG_automa.event.type}),cat_names{cat_idx}) == 1); %create 5x2 cell array (event type x node_1st_half)
    type_epochs{1,cat_idx} = cell2mat({EEG_automa.event(type_idx{1,cat_idx}).epoch}); % finds indices in epoched data
    type_means{1,cat_idx} = mean(EEG_automa.data(:,:,type_epochs{1,cat_idx}), 3); %calculates means
    type_avg{1,cat_idx} = type_means{1,cat_idx}(el_idx, :); %filter electrode
    
    type_idx{2,cat_idx} = find([EEG_automa.event.node_1st_half] == 0 & strcmp(string({EEG_automa.event.type}),cat_names{cat_idx}) == 1); %create 5x2 cell array (event type x node_1st_half)
    type_epochs{2,cat_idx} = cell2mat({EEG_automa.event(type_idx{2,cat_idx}).epoch}); % finds indices in epoched data
    type_means{2,cat_idx} = mean(EEG_automa.data(:,:,type_epochs{2,cat_idx}), 3); %calculates means
    type_avg{2,cat_idx} = type_means{2,cat_idx}(el_idx, :); %filter electrode
end

%%

f_length = 2; %for 1st_node_half being 0 or 1

%initialize
task_irr_idx = cell(1,f_length);
task_irr_epochs = cell(1,f_length);
task_irr_mean = cell(1,f_length);
task_irr_avg = cell(1,f_length);

task_rel_idx = cell(1,f_length);
task_rel_epochs = cell(1,f_length);
task_rel_mean = cell(1,f_length);
task_rel_avg = cell(1,f_length);

background_idx = cell(1,f_length);
background_epochs = cell(1,f_length);
background_mean = cell(1,f_length);
background_avg = cell(1,f_length);


for k = 1:f_length
    % k = 1 means 1st_node_half ==1, k = 2 means 1st_node_half ==0,
    task_irr_idx{k} = [type_idx{k,1}, type_idx{k,2}]; % Task_Irrelevant sums up 'Other_Buildings','Global_Landmark'
    task_irr_epochs{k} = cell2mat({EEG_automa.event(task_irr_idx{k}).epoch});
    task_irr_mean{k} = mean(EEG_automa.data(:,:,task_irr_epochs{k}), 3);
    task_irr_avg{k} = task_irr_mean{k}(el_idx, :); %filter electrode
    
    task_rel_idx{k} = [type_idx{k,3}, type_idx{k,4}]; % Task-Relevant sums up 'TaskBuilding_Public','TaskBuilding_Residential'
    task_rel_epochs{k} = cell2mat({EEG_automa.event(task_rel_idx{k}).epoch});
    task_rel_mean{k} = mean(EEG_automa.data(:,:,task_rel_epochs{k}), 3);
    task_rel_avg{k} = task_rel_mean{k}(el_idx, :); %filter electrode
    
    background_idx{k} = [type_idx{k,5}]; % Background
    background_epochs{k} = cell2mat({EEG_automa.event(background_idx{k}).epoch});
    background_mean{k} = mean(EEG_automa.data(:,:,background_epochs{k}), 3);
    background_avg{k} = background_mean{k}(el_idx, :); %filter electrode
end


%% Plot ERPs grouped by event type !need to add index for avg{1} and avg{2}!

figure;
hold on;
cColors = {"#EDB120", "#D95319", "#4DBEEE","#77AC30","#7E2F8E"};

plot(EEG_automa.times, task_rel_avg, 'Color', "#EDB120", 'LineWidth', 1.2)
plot(EEG_automa.times, task_irr_avg, 'Color', "#4DBEEE", 'LineWidth', 1.2)
plot(EEG_automa.times, background_avg, 'Color', "#D95319", 'LineWidth', 1.2) % Background

%ylim([-1 2]);
xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot4 Event-Related Potentials at %s',currElec));
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('Task-Relevant Buildings','Task-Irrelevant Buildings','Background')
set(gca,'fontname','arial')


%% Plot ERP grouped by event type x node 1st half

figure;
hold on;


plot(EEG_automa.times, task_rel_avg{1},'LineWidth', 1,'Color',"#0072BD",'LineStyle','-') % Task-Relevant x node
plot(EEG_automa.times, task_irr_avg{1},'LineWidth', 1,'Color',"#D95319",'LineStyle','-') %Task-Irrelevant x node
plot(EEG_automa.times, background_avg{1},'LineWidth', 1,'Color',"#77AC30",'LineStyle','-') %Background x node


plot(EEG_automa.times, task_rel_avg{2},'LineWidth', 1.5,'Color',"#0072BD", 'LineStyle',':') % Task-Relevant x not node
plot(EEG_automa.times, task_irr_avg{2},'LineWidth', 1.5,'Color',"#D95319", 'LineStyle',':') %Task-Irrelevant x not node
plot(EEG_automa.times, background_avg{2},'LineWidth', 1.5,'Color',"#77AC30", 'LineStyle',':') %Background x not node

xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot 3 ERP at %s - Fixation Objects at DP and non-DP*',currElec),'FontSize',30);
xlabel('time [ms]','FontSize',12);
ylabel('Potential (µV)','FontSize',12);
legend({'Task-Relevant Buildings at DP', 'Task-Irrelevant Buildings at DP', 'Background at DP', 'Task-Relevant Buildings at Non-DP', 'Task-Irrelevant Buildings at Non-DP', 'Background at Non-DP'},'FontSize',20)

set(gca,'fontname','arial')
%% Fixation Objets at DP vs. non DP with difference curves
figure;

% Upper plot 
subplot(7, 1, [1 4]); 
hold on;
plot(EEG_automa.times, task_rel_avg{1},'LineWidth', 1,'Color',"#0072BD",'LineStyle','-') % Task-Relevant x node
plot(EEG_automa.times, task_irr_avg{1},'LineWidth', 1,'Color',"#D95319",'LineStyle','-') %Task-Irrelevant x node
plot(EEG_automa.times, background_avg{1},'LineWidth', 1,'Color',"#77AC30",'LineStyle','-') %Background x node

plot(EEG_automa.times, task_rel_avg{2},'LineWidth', 1.5,'Color',"#0072BD", 'LineStyle',':') % Task-Relevant x not node
plot(EEG_automa.times, task_irr_avg{2},'LineWidth', 1.5,'Color',"#D95319", 'LineStyle',':') %Task-Irrelevant x not node
plot(EEG_automa.times, background_avg{2},'LineWidth', 1.5,'Color',"#77AC30", 'LineStyle',':') %Background x not node

xlim([-250 800]);
line([0, 0], ylim, 'Color', 'k');
title(sprintf('Pilot 3 ERP at %s - Fixation Objects at DP and non-DP*',currElec),'FontSize',30);
xlabel('time [ms]','FontSize',12);
ylabel('Potential (µV)','FontSize',12);
legend({'Task-Relevant Buildings at DP', 'Task-Irrelevant Buildings at DP', 'Background at DP', 'Task-Relevant Buildings at Non-DP', 'Task-Irrelevant Buildings at Non-DP', 'Background at Non-DP'},'FontSize',16)
set(gca,'fontname','arial')

% Lower subplot 1 (difference curve between task_rel_avg{1} and task_rel_avg{2})
subplot(7, 1, 5); 
hold on;
plot(EEG_automa.times, task_rel_avg{1} - task_rel_avg{2}, 'Color', "#0072BD", 'LineWidth', 1.2)
line(xlim, [0, 0], 'Color', 'k'); % Add horizontal line at y=0
xlim([-250 800]);
ylim([-10 10]);
line([0, 0], ylim, 'Color', 'k'); % Add vertical line at x=0
xlabel('time [ms]');
ylabel('Difference (µV)');
title('Difference Curve: Task-Relevant Buildings', 'FontSize', 16);
set(gca, 'fontname', 'arial');

% Lower subplot 2 (difference curve between task_irr_avg{1} and task_irr_avg{2})
subplot(7, 1, 6); 
hold on;
plot(EEG_automa.times, task_irr_avg{1} - task_irr_avg{2}, 'Color', "#D95319", 'LineWidth', 1.2)
line(xlim, [0, 0], 'Color', 'k'); % Add horizontal line at y=0
xlim([-250 800]);
ylim([-10 10]);
line([0, 0], ylim, 'Color', 'k'); % Add vertical line at x=0
xlabel('time [ms]');
ylabel('Difference (µV)');
title('Difference Curve: Task-Irrelevant Buildings', 'FontSize', 16);
set(gca, 'fontname', 'arial');

% Lower subplot 3 (difference curve between background_avg{1} and background_avg{2})
subplot(7, 1, 7); 
hold on;
plot(EEG_automa.times, background_avg{1} - background_avg{2}, 'Color', "#77AC30", 'LineWidth', 1.2)
line(xlim, [0, 0], 'Color', 'k'); % Add horizontal line at y=0
xlim([-250 800]);
ylim([-10 10]);
line([0, 0], ylim, 'Color', 'k'); % Add vertical line at x=0
xlabel('time [ms]');
ylabel('Difference (µV)');
title('Difference Curve: Background', 'FontSize', 16);
set(gca, 'fontname', 'arial');


%%
figure;

% Plot for Task-Relevant
subplot(3, 1, 1);
hold on;

line_styles = {'-', ':'};
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, task_rel_avg{k}, 'LineWidth', 1, 'Color', "#0072BD", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Fixation-ERPs for Task-Relevant Event Types');
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot for Task-Irrelevant
subplot(3, 1, 2);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, task_irr_avg{k}, 'LineWidth', 1, 'Color', "#D95319", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Fixation-ERPs for Task-Irrelevant Event Types');
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot for Background
subplot(3, 1, 3);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, background_avg{k}, 'LineWidth', 1, 'Color', "#77AC30", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Fixation-ERPs for Background Event Types');
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

%% Same but for all 5 event types
figure;

% Plot for Other Buildings
subplot(5, 1, 1);
hold on;

line_styles = {'-', ':'};

for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, type_avg{k,1}, 'LineWidth', 1, 'Color', "#0072BD", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Other Buildings');
xlim([-250 500]);
%ylim([-20 30]);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot for Global Landmarks
subplot(5, 1, 2);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, type_avg{k,2}, 'LineWidth', 1, 'Color', "#D95319", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Global Landmarks');
xlim([-250 500]);
%ylim([-20 30]);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot Task-Relevant Buildings (Residential)
subplot(5, 1, 3);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, type_avg{k,3}, 'LineWidth', 1, 'Color', "#A2142F", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Task-Relevant Buildings (Residential)');
xlim([-250 500]);
%ylim([-20 30]);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot for Task-Relevant Buildings (Public)
subplot(5, 1, 4);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, type_avg{k,4}, 'LineWidth', 1, 'Color', "#77AC30", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Task-Relevant Buildings (Public)');
xlim([-250 500]);
%ylim([-20 30]);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');

% Plot for Background
subplot(5, 1, 5);
hold on;
for k = 1:f_length
    line_style = line_styles{k};
    plot(EEG_automa.times, type_avg{k,5}, 'LineWidth', 1, 'Color', "#4DBEEE", 'LineStyle', line_style);
end
line([0, 0], ylim, 'Color', 'k');
title('Background');
xlim([-250 500]);
%ylim([-20 30]);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('decision points','non-decision points');
%% %% Make one .set file per Category - NOT NEEDED IF SET FILES EXIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% missing values to category
for i = 1:length(EEG_automa.event)
    if ismissing(EEG_automa.event(i).time_diff_type)
        EEG_automa.event(i).time_diff_type = "missing";
    end
end

% replace type with my type data
EEG = EEG_automa;

for i = 1:numel(EEG.event)
    EEG.event(i).type = char(EEG.event(i).time_diff_type); %needs to be char
end
%% remove all other events and epochs - change number to save different segment
cd(data_files);
EEG_5 = pop_selectevent(EEG);


%% load sets in one struct

EEG_structures = {EEG_1, EEG_2, EEG_3, EEG_4, EEG_5};

file = cell(size(EEG_structures));

for i = 1:numel(EEG_structures)
    file{i} = EEG_structures{i};
end



%% Load sets - START HERE IF SETS EXIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(data_files);


%give the filenames to import
filenames = {'Pilot4_EEG_1.set','Pilot4_EEG_2.set','Pilot4_EEG_3.set','Pilot4_EEG_4.set','Pilot4_EEG_5.set'};

file_length = length(filenames);
file = cell(1,file_length); %create empty file where the sets should go

% load sets into the file + epoching
for k = 1:file_length
    file{k} = pop_loadset(sprintf('/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/data/%s',filenames{k}));
    %file{k} = pop_epoch(file{k}, {}, [-0.25 0.8]); already epoched
    file{k} = eeg_checkset(file{k}); %fixes data if something went wrong
end


% calculate channel means of epochs
for k = 1:file_length
    currElec = 'Oz';
    el_idx = find(strcmp({file{k}.chanlocs.labels}, currElec) == 1); %find the index of electrode
    file{k}.mean = mean(file{k}.data(:,:,:), 3);
    file{k}.avg   = file{k}.mean(el_idx, :); 
end

%% Plotting All Channels

pop_timtopo(file{5});

%% Plot ERP per Segment Category

figure;
hold on;
for k = 1:file_length
    plot(file{k}.times, file{k}.avg,'LineWidth', 1,'Color',cColors{k}) % All
  
end
line([0, 0], ylim, 'Color', 'k');
%ylim([-1 2]);
xlim([-250 800]);
title(sprintf('Pilot4 Event-Related Potentials at %s',currElec),'FontSize',30);
xlabel('time [ms]');
ylabel('Potential (µV)');
legend('time segment 1','time segment 2','time segment 3','time segment 4','time segment 5','FontSize',12);
set(gca,'fontname','arial')

%% REPEAT FOR EACH SET FROM HERE
% for use of FieldTrip
addpath('/Users/lunameidoering/Uni/THESIS/MATLAB/fieldtrip-20230118');
ft_defaults

EEG_5 = pop_editset(EEG_5, 'setname', 'Pilot4_EEG_5');
EEG_5 = pop_saveset(EEG_5, 'filename','Pilot4_EEG_5');

cfg = [];
cfg.dataset = '/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/data/Pilot4_EEG_5.set';

%%
data_eeg = ft_preprocessing(cfg); %dauert
%%

%MULTIPLOT
cfg             = [];
cfg.channel     = 'all';
cfg.linewidth   = 1.0;
cfg.linecolor   = 'b';
cfg.showcomment = 'no';
cfg.showscale   = 'no';
%cfg.showoutline   = 'yes';
%cfg.showlabels    = 'yes';
%cfg.xlim = [0.05 0.15];
% cfg.ylim = [-5 5];
figure; ft_multiplotER( cfg, data_eeg);

% TOPOPLOT
limits = [[0.0 0.02];[0.08 0.1];[0.19 0.21];[0.28 0.3];[0.34 0.36]];
for i = 1:5
    cfg = [];
    cfg.xlim = limits(i,:);
    %cfg.zlim = [-1.8 2.4];
    %cfg.zlim = [-2 2];
    cfg.comment = 'no';
    cfg.colormap = '*RdBu';
    cfg.colorbar = 'yes';
    figure; ft_topoplotER(cfg,data_eeg); %colorbar
    saveas(gcf,sprintf('/Users/lunameidoering/Uni/THESIS/feelSpacedata/ERP/pilot4_topoplot_%d_seg5.jpg',i),'jpg');
end


%% Get the number of trials used for each condition

% Get the number of unique values in each cell
type_trials = cellfun(@(x) numel(unique(x)), type_epochs);
nb_trials = cellfun(@(x) numel(unique(x)), nb_epochs);
grouped_trials = cellfun(@(x) numel(unique(x)), grouped_epochs);

node_trials =  numel(unique(node_epochs));
edge_trials =  numel(unique(edge_epochs));

hnode_trials =  numel(unique(hnode_epochs));
hedge_trials =  numel(unique(hedge_epochs));

