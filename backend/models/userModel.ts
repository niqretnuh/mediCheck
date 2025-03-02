import mongoose, { Schema, Document, Model } from "mongoose";

export interface IUser extends Document {
	name: string;
	email: string;
    medications: string[];
    gender: string;
    dateofbirth: Date
    pregnant: boolean;
}

const userSchema: Schema = new Schema(
	{
        name: { type: String, required: true },
		email: { type: String, required: true },
        medications: [{ type: String, required: true }],
        gender: { type: String, required: true },
        dateofbirth: { type: Date, required: true },
        pregnant: { type: Boolean, required: true }
	},
	{
		timestamps: true,
	}
);

const User: Model<IUser> = mongoose.model<IUser>("User", userSchema);

export default User;
