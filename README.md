![](docs/boltz1_pred_figure.png)

# NVIDIA DGX Spark/GB10-compatible Boltz
## Introduction

Boltz is a family of models for biomolecular interaction prediction. The following fork of Boltz-2 along with set of instructions would enable you to run Boltz2 on NVIDIA's latest GB10 Architecture based DGX Spark. These set of instructions should allow you to run Boltz2 on DGX Spark as of January 1, 2026.

As support for GB10-based architectures increases, these instructions may get outdated, I will update the README in case of such breaking changes.

## Pre-requisites

- Familiarity with Python Environments
- Updated DGX Spark with CUDA >=13.0

## Installation

> Note: recommended to installing boltz-gb10-spark in a fresh python/conda environment

```
git clone https://github.com/sanjyotshenoy/boltz-gb10-spark.git
cd boltz; chmod +x install.sh; ./install.sh
```

The install script should help install the dependcies which will take care of the errors plaguing the normal installation and standard dependencies of boltz.

# Explanation of how the compatibility issues were resolved

It was a multi-step process to trouble-shoot the problem. When I first ran the standard installation of Boltz-2, 
the prediction was stuck at Predicting stage
```
LOCAL_RANK: 0 - CUDA_VISIBLE_DEVICES: [0]
Predicting: |                                                                                                | 0/? [00:00<?, ?it/s]^C
``` 
I was not able to trouble-shoot this issue myself. Thanks to my friend [Ramith Hettiarachchi](https://bsky.app/profile/ramith.fyi) for pointing out a simple fix :- setting `num_workers` to `0`. This moved the prediction script to a new error:

```
ImportError: Error importing triangle_multiplicative_update from cuequivariance_ops_torch.
Predicting DataLoader 0:   0%|          | 0/1 [00:15<?, ?it/s]
```

After a bit of searching around, I stumbled upon the official cuEquivariance's GitHub Repository.
The repository's README gave the fix. Boltz-2's standard `[cuda]` dependencies don't contain `cuequivariance-ops-torch-cu13`, the CUDA 13.0 Kernels for cuEquivariance NVIDIA Python Library.
This resolved this issue and then I was greeted with a massive error log which gave enough clues as to what the issue was:

```
[...]
================================================================
Internal Triton PTX codegen error
`ptxas` stderr:
ptxas fatal   : Value 'sm_121a' is not defined for option 'gpu-name'

[...]
triton.runtime.errors.PTXASError: PTXAS error: Internal Triton PTX codegen error
`ptxas` stderr:
ptxas fatal   : Value 'sm_121a' is not defined for option 'gpu-name'
```

There were issues with Triton, the python library which converses between Python and CUDA. A solution to this was to install the Triton-Nightly (3.6) which has support for Blackwell Architectures. The idea for this was also inspired by this blog post about [installing OpenFold3 by Adrian Carr](https://www.linkedin.com/posts/adrian-carr-56b99985_github-adrian-greenneuronopenfold3-dgx-spark-activity-7407355321888854016-gNQG) which mentions installation of Triton Nightly builds for Kernel Support.

After uninstalling the standard triton and reinstalling the nightly build, finally the Boltz inference ran! Keeping these bug fixes in mind, I have created this Boltz fork and installation script (`install.sh`) which should allow you to run Boltz inference on a GB10-based NVIDIA DGX Spark. Thanks once again to Ramith Hettiarachchi for testing this installation pipeline.

The rest of this README is verbatim of Boltz's Official GitHub Repository README!

## Inference

You can run inference using Boltz with:

```
boltz predict input_path --use_msa_server
```

`input_path` should point to a YAML file, or a directory of YAML files for batched processing, describing the biomolecules you want to model and the properties you want to predict (e.g. affinity). To see all available options: `boltz predict --help` and for more information on these input formats, see our [prediction instructions](docs/prediction.md). By default, the `boltz` command will run the latest version of the model.


### Binding Affinity Prediction
There are two main predictions in the affinity output: `affinity_pred_value` and `affinity_probability_binary`. They are trained on largely different datasets, with different supervisions, and should be used in different contexts. The `affinity_probability_binary` field should be used to detect binders from decoys, for example in a hit-discovery stage. Its value ranges from 0 to 1 and represents the predicted probability that the ligand is a binder. The `affinity_pred_value` aims to measure the specific affinity of different binders and how this changes with small modifications of the molecule. This should be used in ligand optimization stages such as hit-to-lead and lead-optimization. It reports a binding affinity value as `log10(IC50)`, derived from an `IC50` measured in `μM`. More details on how to run affinity predictions and parse the output can be found in our [prediction instructions](docs/prediction.md).

## Authentication to MSA Server

When using the `--use_msa_server` option with a server that requires authentication, you can provide credentials in one of two ways. More information is available in our [prediction instructions](docs/prediction.md).
 
## Evaluation

⚠️ **Coming soon: updated evaluation code for Boltz-2!**

To encourage reproducibility and facilitate comparison with other models, on top of the existing Boltz-1 evaluation pipeline, we will soon provide the evaluation scripts and structural predictions for Boltz-2, Boltz-1, Chai-1 and AlphaFold3 on our test benchmark dataset, and our affinity predictions on the FEP+ benchmark, CASP16 and our MF-PCBA test set.

![Affinity test sets evaluations](docs/pearson_plot.png)
![Test set evaluations](docs/plot_test_boltz2.png)


## Training

⚠️ **Coming soon: updated training code for Boltz-2!**

If you're interested in retraining the model, currently for Boltz-1 but soon for Boltz-2, see our [training instructions](docs/training.md).


## Contributing

We welcome external contributions and are eager to engage with the community. Connect with us on our [Slack channel](https://boltz.bio/join-slack) to discuss advancements, share insights, and foster collaboration around Boltz-2.

On recent NVIDIA GPUs, Boltz leverages the acceleration provided by [NVIDIA  cuEquivariance](https://developer.nvidia.com/cuequivariance) kernels. Boltz also runs on Tenstorrent hardware thanks to a [fork](https://github.com/moritztng/tt-boltz) by Moritz Thüning.

## License

Our model and code are released under MIT License, and can be freely used for both academic and commercial purposes.


## Cite

If you use this code or the models in your research, please cite the following papers:

```bibtex
@article{passaro2025boltz2,
  author = {Passaro, Saro and Corso, Gabriele and Wohlwend, Jeremy and Reveiz, Mateo and Thaler, Stephan and Somnath, Vignesh Ram and Getz, Noah and Portnoi, Tally and Roy, Julien and Stark, Hannes and Kwabi-Addo, David and Beaini, Dominique and Jaakkola, Tommi and Barzilay, Regina},
  title = {Boltz-2: Towards Accurate and Efficient Binding Affinity Prediction},
  year = {2025},
  doi = {10.1101/2025.06.14.659707},
  journal = {bioRxiv}
}

@article{wohlwend2024boltz1,
  author = {Wohlwend, Jeremy and Corso, Gabriele and Passaro, Saro and Getz, Noah and Reveiz, Mateo and Leidal, Ken and Swiderski, Wojtek and Atkinson, Liam and Portnoi, Tally and Chinn, Itamar and Silterra, Jacob and Jaakkola, Tommi and Barzilay, Regina},
  title = {Boltz-1: Democratizing Biomolecular Interaction Modeling},
  year = {2024},
  doi = {10.1101/2024.11.19.624167},
  journal = {bioRxiv}
}
```

In addition if you use the automatic MSA generation, please cite:

```bibtex
@article{mirdita2022colabfold,
  title={ColabFold: making protein folding accessible to all},
  author={Mirdita, Milot and Sch{\"u}tze, Konstantin and Moriwaki, Yoshitaka and Heo, Lim and Ovchinnikov, Sergey and Steinegger, Martin},
  journal={Nature methods},
  year={2022},
}
```
