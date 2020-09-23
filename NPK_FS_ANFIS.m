clc; 
dataset = readtable('NPK');
X = dataset(:,2:4);
Y = dataset(:,5:7);
X = table2array(X);
Y = table2array(Y);

% [idx,scores] = fsrftest(X,Y(:,1));
% find(isinf(scores));
% bar(scores(idx));
% xlabel('Predictor Rank');
% ylabel('Predictor Importance Score');

X = X(:,1:2);
%X(:,2)=[];
X = normalize(X);
%X(:,3) = [];
Y = Y(:,1);
nData = size(X,1);
%% Shuffling Data
PERM = randperm(nData); % Permutation to Shuffle Data
pTrain=0.70;
nTrainData=round(pTrain*nData);
TrainInd=PERM(1:nTrainData);
TrainInputs=X(TrainInd,:);
TrainTargets=Y(TrainInd,:);
pTest=1-pTrain;
nTestData=nData-nTrainData;
TestInd=PERM(nTrainData+1:end);
TestInputs=X(TestInd,:);
TestTargets=Y(TestInd,:);

%TrainInputs = normalize(TrainInputs(:,1:2))
%TestInputs = normalize(TestInputs(:,1:2))
%TrainInputs = [TrainInputs, (TrainInputs(:,3))] 
%TestInputs = [TestInputs, (TestInputs(:,3))] 

% colNames = {'Temp','pH','Nitrate'}
% TrainInputs = table2array(TrainInputs, 'VariableNames',colNames)
% TestInputs = table2array(TestInputs, 'VariableNames',colNames)
%% Selection of FIS Generation Method
Option{1}='Grid Partitioning (genfis1)';
Option{2}='Subtractive Clustering (genfis2)';
Option{3}='FCM (genfis3)';
ANSWER=questdlg('Select FIS Generation Approach:',...
                'Select GENFIS',...
                Option{1},Option{2},Option{3},...
                Option{3});
pause(0.01);
%% Setting the Parameters of FIS Generation Methods
switch ANSWER
    case Option{1}
        Prompt={'Number of MFs','Input MF Type:','Output MF Type:'};
        Title='Enter genfis1 parameters';
        DefaultValues={'5', 'gaussmf', 'linear'};
        
        PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
        pause(0.01);
        nMFs=str2num(PARAMS{1});	%#ok
        InputMF=PARAMS{2};
        OutputMF=PARAMS{3};
        
        fis=genfis1([TrainInputs TrainTargets],nMFs,InputMF,OutputMF);
    case Option{2}
        Prompt={'Influence Radius:'};
        Title='Enter genfis2 parameters';
        DefaultValues={'0.3'};
        
        PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
        pause(0.01);
        Radius=str2num(PARAMS{1});	%#ok
        
        fis=genfis2(TrainInputs,TrainTargets,Radius);
        
    case Option{3}
        Prompt={'Number fo Clusters:',...
                'Partition Matrix Exponent:',...
                'Maximum Number of Iterations:',...
                'Minimum Improvemnet:'};
        Title='Enter genfis3 parameters';
        DefaultValues={'15', '2', '200', '1e-5'};
        
        PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
        pause(0.01);
        nCluster=str2num(PARAMS{1});        %#ok
        Exponent=str2num(PARAMS{2});        %#ok
        MaxIt=str2num(PARAMS{3});           %#ok
        MinImprovment=str2num(PARAMS{4});	%#ok
        DisplayInfo=1;
        FCMOptions=[Exponent MaxIt MinImprovment DisplayInfo];
        
        fis=genfis3(TrainInputs,TrainTargets,'sugeno',nCluster,FCMOptions);
end
%% Training ANFIS Structure
Prompt={'Maximum Number of Epochs:',...
        'Error Goal:',...
        'Initial Step Size:',...
        'Step Size Decrease Rate:',...
        'Step Size Increase Rate:'};
Title='Enter genfis3 parameters';
DefaultValues={'200', '0', '0.01', '0.9', '1.1'};
PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
pause(0.01);
MaxEpoch=str2num(PARAMS{1});                %#ok
ErrorGoal=str2num(PARAMS{2});               %#ok
InitialStepSize=str2num(PARAMS{3});         %#ok
StepSizeDecreaseRate=str2num(PARAMS{4});    %#ok
StepSizeIncreaseRate=str2num(PARAMS{5});    %#ok
TrainOptions=[MaxEpoch ...
              ErrorGoal ...
              InitialStepSize ...
              StepSizeDecreaseRate ...
              StepSizeIncreaseRate];
DisplayInfo=true;
DisplayError=true;
DisplayStepSize=true;
DisplayFinalResult=true;
DisplayOptions=[DisplayInfo ...
                DisplayError ...
                DisplayStepSize ...
                DisplayFinalResult];
OptimizationMethod=1;
% 0: Backpropagation
% 1: Hybrid
            
fis=anfis([TrainInputs TrainTargets],fis,TrainOptions,DisplayOptions,[],OptimizationMethod);
%% Apply ANFIS to Data
Outputs=evalfis(X,fis);
TrainOutputs=Outputs(TrainInd,:);
TestOutputs=Outputs(TestInd,:);
%% Error Calculation
TrainErrors=TrainTargets-TrainOutputs;
TrainMSE=mean(TrainErrors.^2);
TrainRMSE=sqrt(TrainMSE);
TrainErrorMean=mean(TrainErrors);
TrainErrorSTD=std(TrainErrors);
TestErrors=TestTargets-TestOutputs;
TestMSE=mean(TestErrors.^2);
TestRMSE=sqrt(TestMSE);
TestErrorMean=mean(TestErrors);
TestErrorSTD=std(TestErrors);
% %% Plot Results
% figure;
% scatter(TrainTargets,TrainOutputs);
% figure;
% scatter(TestTargets,TestOutputs);
% figure;
% scatter(Targets,Outputs,'All Data');
% if ~isempty(which('plotregression'))
%     figure;
%     plotregression(TrainTargets, TrainOutputs, 'Train Data', ...
%                    TestTargets, TestOutputs, 'Test Data', ...
%                    Targets, Outputs, 'All Data');
%     set(gcf,'Toolbar','figure');
% end
% figure;
% gensurf(fis, [1 2], 1, [30 30]);
% xlim([min(X_Temp_pH(:,1)) max(X_Temp_pH(:,1))]);
% ylim([min(X_Temp_pH(:,2)) max(X_Temp_pH(:,2))]);