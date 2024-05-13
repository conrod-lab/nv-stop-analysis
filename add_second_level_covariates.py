import pandas as pd
import os 
import nibabel as nib
from nilearn import datasets
from nilearn.input_data import NiftiLabelsMasker

# import the csv file to be appended to 
df = pd.read_csv('second_level_confounds.csv', sep=' ')

# add column names subject_id and session_id to the dataframe
df.columns = ['subject_id', 'session_id']

# remove duplicates
df = df.drop_duplicates()

# reorder by subject id
df = df.sort_values(by='subject_id')

print(df.head())

# read in covariates excel file
covariates = pd.read_excel('nv_covariates.xlsx')

# remove the first row which is a duplicate of the columns
covariates = covariates.drop([0])

# create a new column called subject_id that takes in 
# the ID column of integers 1, 2, ..., 155 and converts
# them to sub-XXX. Do the same thing and create session_id 
# from the Time column
covariates['subject_id'] = covariates['ID'].apply(lambda x: 'sub-{:03d}'.format(x))
covariates['session_id'] = covariates['Time'].apply(lambda x: 'ses-{:02d}'.format(x))

# Now merge covariates and df on subject_id and session_id but only keep the ones 
# from df and drop any extras found in covariates
covariates = pd.merge(df, covariates, on=['subject_id', 'session_id'], how='left')

# now use nilearn to read in the nii.gz contrast map and extract 
# the ROIs using the aal map that will be added to the covariates dataframe
# the filename is sub-001_ses-01_task-stop_run-01_zmap-stopsuccess-stopfail.nii.gz

# first create a list of all the files in the directory
files = os.listdir('.')
files = [f for f in files if f.endswith('.nii.gz')]
print(files)

# Load the AAL atlas
aal_atlas = datasets.fetch_atlas_aal()
aal_img = nib.load(aal_atlas.maps)

# now iterate through the files and extract the subject_id and session_id
# and add the ROI values to the covariates dataframe
roi_df_list = []
for f in files:
    subject_id = f.split('_')[0]
    session_id = f.split('_')[1]
    print(subject_id, session_id)

    # Load the contrast map
    contrast_map_img = nib.load(f)
    # Initialize masker with AAL atlas
    masker = NiftiLabelsMasker(labels_img=aal_img, standardize=True)

    # Extract ROI values
    roi_values = masker.fit_transform(contrast_map_img)

    # put it in a dataframe and use aal_atlas.labels to name the columns
    #roi_values = pd.DataFrame(roi_values, columns=aal_atlas.labels)
    # instead make a dictionary where the keys are the ROI names and the values are the ROI values
    roi_values_dict = dict(zip(aal_atlas.labels, [r[0] for r in roi_values.T]))
    # add the subject_id and session_id to the dataframe
    # roi_values['subject_id'] = subject_id
    # roi_values['session_id'] = session_id

    roi_values_dict = {'subject_id': subject_id, 'session_id': session_id, **roi_values_dict}
    roi_df_list.append(roi_values_dict)
    # merge the roi_values dataframe with the covariates dataframe
    #covariates = pd.merge(covariates, roi_values, on=['subject_id', 'session_id'], how='left')
    # Merge with covariates DataFrame
    

    # Filter for HasfMRI==1 and drop the column
    #covariates = covariates[covariates['HasfMRI'] == 1].drop('HasfMRI', axis=1)
# drop ID and Time
roi_df = pd.DataFrame(roi_df_list)
covariates = pd.merge(covariates, roi_df, on=['subject_id', 'session_id'], how='left')
covariates = covariates.drop(['ID', 'Time'], axis=1)

print(covariates.head())