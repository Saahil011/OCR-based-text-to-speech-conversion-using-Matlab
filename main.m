
% Clear all and initialize
clc;
clear all;
close all;

% Image Processing and OCR
try
    % Load and preprocess the image
    imagePath = ['test1.jpg']; % Replace with your image path
    colorImage = imread(imagePath);
    figure;
    imshow(colorImage);
    title('Input Image/Original Unprocessed Image');
    
    % Convert to grayscale
    grayImage = rgb2gray(colorImage);
    th = graythresh(grayImage);
    figure;
    imshow(grayImage);
    title('gray image')
    
    % Binary Image
    bwImage = ~im2bw(grayImage, th);
    figure;
    imshow(bwImage);
    title('Binary Image');
    
    % Apply OCR
    ocrResults = ocr(bwImage);
    
    % Recognized Text
    recognizedText = ocrResults.Text;
    disp('Recognized Text:');
    disp(recognizedText);
    
    % Display Bounding Boxes
    Iocr = insertObjectAnnotation(colorImage, 'rectangle', ...
        ocrResults.WordBoundingBoxes, ocrResults.WordConfidences);
    figure;
    imshow(Iocr);
    title('Bounding Boxes with Recognized Text');

    % Check if OCR detected any words
    if ~isempty(ocrResults.Words)
        for n = 1:numel(ocrResults.Words)
            % Extract each word
            word = ocrResults.Words{n};
            disp(['Processing word: ', word]);
            
            % Text-to-Speech for Each Word
            NET.addAssembly('System.Speech');
            mysp = System.Speech.Synthesis.SpeechSynthesizer;
            mysp.Volume = 100; % Volume (1-100)
            mysp.Rate = 2; % Speed (-10 to 10)
            
            % Record and Speak
            a = audiorecorder(96000, 16, 1); % Create object for recording audio
            record(a, 2); % Record 2 seconds for each word
            Speak(mysp, word); % Expressing each word
            stop(a); % Stop recording

            % Get recorded audio data
            b = getaudiodata(a);

            % Plot the sound wave
            figure;
            plot(b);
            title(['Sound Wave Plot for Word: ', word]);
            xlabel('Time (samples)');
            ylabel('Amplitude');
        end
    else
        disp('No words were detected in the image.');
    end
catch ME
    disp('An error occurred during OCR or text processing:');
    disp(ME.message);
end

% Advanced Image Processing (Stroke Width Variation Filter for Complex Images)
try
    % Detect MSER regions
    [mserRegions, mserConnComp] = detectMSERFeatures(grayImage, ...
        'RegionAreaRange', [200 8000], 'ThresholdDelta', th);
    
    % Display MSER regions
    figure;
    imshow(grayImage);
    hold on;
    plot(mserRegions, 'showPixelList', true, 'showEllipses', false);
    title('MSER Regions');
    hold off;
    
    % Filter regions based on stroke width
    mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');
    strokeWidthThreshold = 0.4; % Adjust threshold if needed
    strokeWidthFilterIdx = false(size(mserStats));
    
    for j = 1:numel(mserStats)
        regionImage = padarray(mserStats(j).Image, [1 1], 0);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        strokeWidthValues = distanceImage(skeletonImage);
        strokeWidthMetric = std(strokeWidthValues) / mean(strokeWidthValues);
        strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;
    end
    
    % Remove non-text regions
    mserRegions(strokeWidthFilterIdx) = [];
    mserStats(strokeWidthFilterIdx) = [];
    
    % Get bounding boxes for filtered regions
    bboxes = vertcat(mserStats.BoundingBox);
    expandedBBoxes = bboxes + [-2 -2 4 4]; % Expand bounding boxes slightly
    IExpandedBBoxes = insertShape(colorImage, 'Rectangle', expandedBBoxes, 'LineWidth', 3);
    
    figure;
    imshow(IExpandedBBoxes);
    title('Filtered Text Bounding Boxes');
catch ME
    disp('An error occurred during advanced image processing:');
    disp(ME.message);
end

% Save the Recognized Text
try
    fid = fopen('recognized_text.txt', 'w');
    fprintf(fid, '%s\n', recognizedText);
    fclose(fid);
    disp('Recognized text saved to recognized_text.txt');
catch ME
    disp('An error occurred while saving the recognized text:');
    disp(ME.message);
end
