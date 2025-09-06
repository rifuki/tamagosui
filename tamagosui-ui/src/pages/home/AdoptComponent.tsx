import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { useMutateAdoptPet } from "@/hooks/useMutateAdoptPet";
import { Loader2Icon } from "lucide-react";

const INTIAAL_PET_IMAGE_URL =
  "https://raw.githubusercontent.com/xfajarr/stacklend/refs/heads/main/photo_2023-04-30_12-46-11.jpg";

export default function AdoptComponent() {
  const [petName, setPetName] = useState("");
  const { mutate: mutateAdoptPet, isPending: isAdopting } = useMutateAdoptPet();

  const handleAdoptPet = () => {
    if (!petName.trim()) return;
    mutateAdoptPet({ name: petName });
  };

  return (
    <Card className="w-full max-w-sm text-center shadow-hard border-2 border-primary">
      <CardHeader>
        <CardTitle className="text-3xl">ADOPT YOUR PET</CardTitle>
        <CardDescription>A new friend awaits!</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <img
            src={INTIAAL_PET_IMAGE_URL}
            alt="Your new pet"
            className="w-40 h-40 mx-auto image-rendering-pixelated bg-secondary p-2 border-2 border-primary"
          />
        </div>

        <div className="space-y-2">
          <p className="text-lg">What will you name it?</p>
          <Input
            value={petName}
            onChange={(e) => setPetName(e.target.value)}
            placeholder="Enter pet's name"
            disabled={isAdopting}
            className="text-center text-lg border-2 border-primary focus:ring-2 focus:ring-offset-2 focus:ring-ring"
          />
        </div>

        <div>
          <Button
            onClick={handleAdoptPet}
            disabled={!petName.trim() || isAdopting}
            className="w-full text-lg py-6 border-2 border-primary shadow-hard-sm hover:translate-x-0.5 hover:translate-y-0.5"
          >
            {isAdopting ? (
              <>
                <Loader2Icon className="mr-2 h-5 w-5 animate-spin" />{" "}
                Adopting...
              </>
            ) : (
              "ADOPT NOW"
            )}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
