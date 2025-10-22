import requests
import json
import os
import argparse
import sys
from datetime import datetime


def parse_fasta(fasta_file):
    """Parse FASTA file and return sequences with metadata"""
    sequences = []
    current_seq = ""
    current_header = ""
    
    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                # Save previous sequence if exists
                if current_header and current_seq:
                    # Extract chain info from header
                    header_parts = current_header.split('|')
                    chain_id = header_parts[0] if header_parts else current_header
                    description = current_header
                    
                    # Create short ID (max 4 chars for API)
                    short_id = chain_id[:4] if len(chain_id) <= 4 else f"C{len(sequences)+1}"
                    
                    sequences.append({
                        'id': chain_id,
                        'short_id': short_id,
                        'description': description,
                        'sequence': current_seq
                    })
                
                # Start new sequence
                current_header = line[1:]  # Remove '>'
                current_seq = ""
            else:
                current_seq += line
        
        # Don't forget the last sequence
        if current_header and current_seq:
            header_parts = current_header.split('|')
            chain_id = header_parts[0] if header_parts else current_header
            description = current_header
            short_id = chain_id[:4] if len(chain_id) <= 4 else f"C{len(sequences)+1}"
            
            sequences.append({
                'id': chain_id,
                'short_id': short_id,
                'description': description,
                'sequence': current_seq
            })
    
    return sequences


def make_prediction_request(sequence, output_format="mmcif", chain_id="A"):
    """Make a prediction request to Boltz2"""
    headers = {
        "content-type": "application/json"
    }
    data = {
        "polymers": [
            {
                "id": chain_id,
                "molecule_type": "protein",
                "sequence": sequence
            }
        ],
        "recycling_steps": 3,
        "sampling_steps": 50,
        "diffusion_samples": 1,
        "step_scale": 1.638,
        "output_format": output_format
    }
    
    print(f"Making prediction request ({output_format} format)...")
    response = requests.post("http://localhost:8000/biology/mit/boltz2/predict", headers=headers, data=json.dumps(data))
    return response.json()


def save_structures_and_metadata(result, base_filename="prediction"):
    """Save structure CIF files and additional metadata"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    saved_files = []
    
    if result.get("structures"):
        print(f"Found {len(result['structures'])} structure(s)")
        
        # Save each structure as CIF file
        for i, structure in enumerate(result["structures"]):
            if structure.get('format') == 'mmcif':
                confidence_score = result['confidence_scores'][i] if i < len(result.get('confidence_scores', [])) else 0.0
                structure_filename = f"{base_filename}_structure_{i+1}_{timestamp}_{confidence_score:.3f}.cif"
                
                with open(structure_filename, 'w') as f:
                    f.write(structure['structure'])
                
                print(f"Structure {i+1} saved to: {structure_filename}")
                print(f"   Confidence score: {confidence_score:.3f}")
                print(f"   File size: {os.path.getsize(structure_filename)} bytes")
                saved_files.append(structure_filename)
        
        # Save confidence scores and metrics in a separate file
        metrics_data = {
            "timestamp": timestamp,
            "confidence_scores": result.get('confidence_scores', []),
            "average_confidence": sum(result.get('confidence_scores', [0]))/len(result.get('confidence_scores', [1])),
            "max_confidence": max(result.get('confidence_scores', [0])),
            "min_confidence": min(result.get('confidence_scores', [0])),
            "num_structures": len(result['structures']),
            "structure_formats": [s.get('format') for s in result['structures']]
        }
        
        # Add timing information if available
        if 'metrics' in result:
            timing_metrics = result['metrics']
            metrics_data['timing'] = {
                'total_time_seconds': timing_metrics.get('total_time_seconds', 0),
                'input_preparation_time_seconds': timing_metrics.get('input_preparation_time_seconds', 0),
                'model_inference_time_seconds': timing_metrics.get('model_inference_time_seconds', 0),
                'postprocessing_time_seconds': timing_metrics.get('postprocessing_time_seconds', 0),
                'dataloader_setup_time_seconds': timing_metrics.get('dataloader_setup_time_seconds', 0)
            }
            # Add total time in minutes for convenience
            metrics_data['timing']['total_time_minutes'] = timing_metrics.get('total_time_seconds', 0) / 60
        
        # Add additional scores and metrics
        score_fields = ['ptm_scores', 'iptm_scores', 'complex_plddt_scores', 'complex_iplddt_scores', 'complex_pde_scores']
        for field in score_fields:
            if field in result:
                metrics_data[field] = result[field]
        
        # Add any additional output metrics from the result
        for key, value in result.items():
            if key not in ['structures', 'confidence_scores', 'metrics'] and not isinstance(value, (list, dict)) or key in ['total_time', 'processing_time', 'energy', 'rmsd', 'plddt']:
                metrics_data[f"output_{key}"] = value
        
        metrics_filename = f"{base_filename}_metrics_{timestamp}.json"
        with open(metrics_filename, 'w') as f:
            json.dump(metrics_data, f, indent=2)
        
        print(f"Confidence scores and metrics saved to: {metrics_filename}")
        saved_files.append(metrics_filename)
        
        # Save additional metadata as JSON file (excluding metrics already saved above)
        metadata = {
            "timestamp": timestamp,
            "request_parameters": {
                "recycling_steps": 3,
                "sampling_steps": 50,
                "diffusion_samples": 1,
                "step_scale": 1.638,
                "output_format": "mmcif"
            },
            "file_info": {
                "structure_files": [f for f in saved_files if f.endswith('.cif')],
                "metrics_file": metrics_filename
            }
        }
        
        # Add any additional non-metric fields from result
        for key, value in result.items():
            if key not in ['structures', 'confidence_scores'] and key not in metrics_data:
                metadata['additional_info'] = metadata.get('additional_info', {})
                metadata['additional_info'][key] = value
        
        metadata_filename = f"{base_filename}_metadata_{timestamp}.json"
        with open(metadata_filename, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"Metadata saved to: {metadata_filename}")
        saved_files.append(metadata_filename)
        
        # Save summary as TXT file
        summary_filename = f"{base_filename}_summary_{timestamp}.txt"
        with open(summary_filename, 'w') as f:
            f.write(f"Boltz2 Prediction Summary\n")
            f.write(f"========================\n")
            f.write(f"Timestamp: {timestamp}\n")
            f.write(f"Number of structures: {len(result['structures'])}\n")
            f.write(f"Confidence scores: {result.get('confidence_scores', [])}\n")
            f.write(f"Average confidence: {sum(result.get('confidence_scores', [0]))/len(result.get('confidence_scores', [1])):.3f}\n")
            
            # Add timing information if available
            if 'metrics' in result:
                total_time = result['metrics'].get('total_time_seconds', 0)
                f.write(f"Total compute time: {total_time:.2f} seconds ({total_time/60:.2f} minutes)\n")
                f.write(f"Model inference time: {result['metrics'].get('model_inference_time_seconds', 0):.2f} seconds\n")
            f.write(f"\nFiles saved:\n")
            f.write(f"Structure files:\n")
            for filename in [f for f in saved_files if f.endswith('.cif')]:
                f.write(f"  - {filename}\n")
            f.write(f"\nMetrics file: {metrics_filename}\n")
            f.write(f"Metadata file: {metadata_filename}\n")
        
        print(f"Summary saved to: {summary_filename}")
        saved_files.append(summary_filename)
        
    else:
        print("No structures found in the response")
    
    return saved_files


def main():
    parser = argparse.ArgumentParser(description='Boltz2 protein structure prediction')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-f', '--fasta', type=str, help='Path to FASTA file containing sequences')
    group.add_argument('-s', '--sequence', type=str, help='Single protein sequence string')
    
    args = parser.parse_args()
    
    if args.fasta:
        # Process FASTA file
        if not os.path.exists(args.fasta):
            print(f"Error: FASTA file '{args.fasta}' not found")
            sys.exit(1)
        
        sequences = parse_fasta(args.fasta)
        print(f"Processing {len(sequences)} sequences from {args.fasta}")
        
        # Create summary filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        summary_filename = f"fasta_processing_summary_{timestamp}.txt"
        
        # Print and write FASTA summary information
        summary_content = []
        summary_content.append("FASTA Processing Summary")
        summary_content.append("=" * 80)
        summary_content.append(f"Input file: {args.fasta}")
        summary_content.append(f"Processing timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        summary_content.append("")
        summary_content.append("FASTA Summary:")
        summary_content.append("=" * 80)
        
        print("\nFASTA Summary:")
        print("=" * 80)
        total_length = 0
        for i, seq_info in enumerate(sequences, 1):
            seq_length = len(seq_info['sequence'])
            total_length += seq_length
            chain_info = f"Chain {i}: {seq_info['short_id']} ({seq_info['description']})"
            length_info = f"  Sequence length: {seq_length} amino acids"
            
            print(chain_info)
            print(length_info)
            
            summary_content.append(chain_info)
            summary_content.append(length_info)
        
        # Add totals to both console and file
        totals_info = [
            f"\nTotal sequences: {len(sequences)}",
            f"Total sequence length: {total_length} amino acids",
            f"Average sequence length: {total_length/len(sequences):.1f} amino acids"
        ]
        
        for info in totals_info:
            print(info)
            summary_content.append(info)
        
        print("=" * 80)
        print()
        summary_content.append("=" * 80)
        summary_content.append("")
        
        # Track all generated files
        all_generated_files = []
        
        for seq_info in sequences:
            chain_id = seq_info['short_id']
            sequence = seq_info['sequence']
            description = seq_info['description']
            
            print(f"\nProcessing chain {chain_id}: {description}")
            print(f"Sequence length: {len(sequence)}")
            
            # Make prediction
            result = make_prediction_request(sequence, "mmcif", chain_id)
            print(f"Structure prediction completed for chain {chain_id}")
            
            # Save structures and metadata
            base_filename = f"boltz2_{chain_id}_prediction"
            saved_files = save_structures_and_metadata(result, base_filename)
            all_generated_files.extend(saved_files)
            
            # Add processing info to summary
            summary_content.append(f"Processing Results for Chain {chain_id}:")
            summary_content.append(f"  Description: {description}")
            summary_content.append(f"  Sequence length: {len(sequence)} amino acids")
            if result.get('structures'):
                confidence = result.get('confidence_scores', [0])[0]
                summary_content.append(f"  Confidence score: {confidence:.3f}")
                if 'metrics' in result:
                    total_time = result['metrics'].get('total_time_seconds', 0)
                    summary_content.append(f"  Compute time: {total_time:.2f} seconds")
            summary_content.append(f"  Files generated: {len(saved_files)}")
            for file in saved_files:
                summary_content.append(f"    - {file}")
            summary_content.append("")
            
            # Final summary for this sequence
            print(f"\nSummary for chain {chain_id}:")
            print(f"Total files saved: {len(saved_files)}")
            for file in saved_files:
                print(f"  - {file}")
            
            print("-" * 60)  # Separator between sequences
        
        # Final overall summary
        overall_summary = [
            "OVERALL SUMMARY:",
            "=" * 80,
            f"Total sequences processed: {len(sequences)}",
            f"Total sequence length: {total_length} amino acids",
            f"Average sequence length: {total_length/len(sequences):.1f} amino acids",
            f"Total files generated: {len(all_generated_files)}",
            "File types per sequence: .cif, .json (metrics), .json (metadata), .txt (summary)",
            "=" * 80,
            "",
            "All Generated Files:",
        ]
        
        # Add all generated files to summary
        for file in all_generated_files:
            overall_summary.append(f"  - {file}")
        
        overall_summary.append("")
        overall_summary.append(f"Processing completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Print to console
        print(f"\nOVERALL SUMMARY:")
        print("=" * 80)
        print(f"Total sequences processed: {len(sequences)}")
        print(f"Total sequence length: {total_length} amino acids")
        print(f"Average sequence length: {total_length/len(sequences):.1f} amino acids")
        print(f"Total files generated: {len(all_generated_files)}")
        print("File types per sequence: .cif, .json (metrics), .json (metadata), .txt (summary)")
        print("=" * 80)
        
        # Add overall summary to content and write to file
        summary_content.extend(overall_summary)
        
        with open(summary_filename, 'w') as f:
            f.write('\n'.join(summary_content))
        
        print(f"\nComplete summary saved to: {summary_filename}")
        print(f"Prediction complete for all sequences!")
    
    elif args.sequence:
        # Process single sequence
        sequence = args.sequence
        print(f"Processing single sequence")
        print(f"Sequence length: {len(sequence)}")
        
        # Make prediction
        result = make_prediction_request(sequence)
        print("Structure prediction completed")
        
        # Save structures and metadata
        saved_files = save_structures_and_metadata(result, "boltz2_prediction")
        
        # Final summary
        print(f"\nSummary:")
        print(f"Total files saved: {len(saved_files)}")
        for file in saved_files:
            print(f"  - {file}")
        
        print(f"\nPrediction complete!")


if __name__ == "__main__":
    main()
