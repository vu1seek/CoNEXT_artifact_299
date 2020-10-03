from utils import *
from os import listdir


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Let us compute the ROC curve.')
    parser.add_argument('--loss-list-fname', type=str, help='1st path to loss list')
    args = parser.parse_args()

    y, scores = read_loss_list(args.loss_list_fname, deduplicate=True)
    y = np.array(y)
    scores = np.array(scores)
    fpr, tpr, thresholds = metrics.roc_curve(y, scores, pos_label=1)
    score = metrics.roc_auc_score(y, scores)
    print(">>>>>>>>> [Overall] AUC_ROC score: %f <<<<<<<<<" % score)
