import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from nilearn import plotting, datasets
import nibabel as nib
from matplotlib.colors import Normalize
from matplotlib.colors import ListedColormap

# Load the AAL atlas
aal_atlas = datasets.fetch_atlas_aal()

# Load the MNI template image
mni_img = datasets.load_mni152_template()

# Load the AAL atlas image
aal_img = nib.load(aal_atlas.maps)

# Make a copy of the AAL atlas data
aal_data = np.copy(aal_img.get_fdata())

# Load T-value data from CSV file
data = pd.read_csv('sleep_roi_tvalues_2.csv')

# Create a dictionary mapping ROI names to T values
roi_t_values = dict(zip(data['ROI'], data['T_Value']))
vmin=min(roi_t_values.values())
vmax=max(roi_t_values.values())

# Iterate over each ROI and update its corresponding voxel value in the AAL atlas copy
for roi_name, t_value in roi_t_values.items():
    try:
        # Get the index of the ROI in the AAL atlas
        roi_index = aal_atlas['indices'][aal_atlas.labels.index(roi_name)]
        # Update the voxel value in the AAL atlas copy
        aal_data[aal_data == int(roi_index)] = float(t_value)
    except ValueError:
        print(f"ROI '{roi_name}' not found in AAL atlas.")


# Create a new Nifti image with the modified AAL atlas data
aal_t_img = nib.Nifti1Image(aal_data, affine=aal_img.affine)

# Plot the modified AAL atlas image on a brain
plotting.plot_glass_brain(aal_t_img, title='P Values on AAL Atlas', display_mode='lyrz', plot_abs=False, colorbar=True, threshold=2.5)



plt.show()