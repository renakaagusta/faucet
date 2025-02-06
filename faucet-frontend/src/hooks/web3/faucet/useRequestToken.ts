import faucetABI from '@/abis/faucet/FaucetABI';
import { wagmiConfig } from '@/configs/wagmi';
import { FAUCET_ADDRESS } from '@/constants/contract-address';
import { HexAddress } from '@/types/web3/general/address';
import { readContract, simulateContract, writeContract } from '@wagmi/core';
import { useState } from 'react';
import { toast } from 'sonner';
import { encodeFunctionData } from 'viem';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

export const useRequestToken = (
) => {
    const [isAlertOpen, setIsAlertOpen] = useState(false);

    const {
        data: requestTokenHash,
        isPending: isRequestTokenPending,
        writeContract: writeRequestToken
    } = useWriteContract();

    const {
        isLoading: isRequestTokenConfirming,
        isSuccess: isRequestTokenConfirmed
    } = useWaitForTransactionReceipt({
        hash: requestTokenHash,
    });

    const handleRequestToken = async (receiverAddress: HexAddress, tokenAddress: HexAddress) => {
        try {
            // const resultSimulation = await readContract(wagmiConfig, {
            //     address: FAUCET_ADDRESS as HexAddress,
            //     abi: faucetABI,
            //     functionName: 'requestToken',
            //     args: [receiverAddress, tokenAddress],
            // });

            // console.log({
            //     resultSimulation
            // })
            
            // Simulate the transaction first
            // const resultSimulation2 =  await simulateContract(wagmiConfig, {
            //     abi: faucetABI,
            //     address: FAUCET_ADDRESS as HexAddress,
            //     functionName: 'requestToken',
            //     args: [receiverAddress, tokenAddress],
            // });

            // console.log({
            //     resultSimulation2
            // })

            // const result = writeRequestToken({

            // If simulation succeeds, send the actual transaction
            // Debug the transaction first using debug_traceCall
            // Since we can't use debug_traceCall, we'll rely on simulateContract 
            // which provides more detailed error information if the call fails
            // const simulation = await simulateContract(wagmiConfig, {
            //     abi: faucetABI,
            //     address: FAUCET_ADDRESS as HexAddress,
            //     functionName: 'requestToken',
            //     args: [receiverAddress, tokenAddress],
            //     account: receiverAddress // Simulate from the receiver's address
            // });

            // console.log('Simulation details:', {
            //     result: simulation.result,
            //     request: simulation.request
            // });

            // If debug trace looks good, proceed with actual transaction
            const result = writeRequestToken({
                abi: faucetABI,
                address: FAUCET_ADDRESS as HexAddress,
                functionName: 'requestToken',
                args: [receiverAddress, tokenAddress],
            });
            console.log({
                result
            })
            // writeContract(wagmiConfig, {
            //     address: FAUCET_ADDRESS,
            //     abi:faucetABI,
            //     functionName: 'requestToken',
            //     args: [receiverAddress, tokenAddress],
            // })

            while (!isRequestTokenConfirmed) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }

            toast.success('Token has been requested');
            setIsAlertOpen(true);
        } catch (error) {
            console.error('Transaction error:', error);
            toast.error(error instanceof Error ? error.message : 'Transaction failed. Please try again.');
        }
    };

    return {
        isAlertOpen,
        setIsAlertOpen,
        requestTokenHash,
        isRequestTokenPending,
        isRequestTokenConfirming,
        handleRequestToken,
        isRequestTokenConfirmed
    };
};