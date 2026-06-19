import { Controller, Get, Post, Put, Body, Query, UseGuards, Req, NotFoundException, BadRequestException, UploadedFiles, UseInterceptors, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { ShopsService } from './shops.service';
import { CloudinaryService } from './cloudinary.service';
import { CreateShopDto } from './dto/create-shop.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('Shops')
@Controller('shops')
export class ShopsController {
  constructor(
    private readonly shopsService: ShopsService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  @Get('my')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Get current user's shop" })
  async getMyShop(@Req() req: any) {
    const ownerId = req.user._id;
    const shop = await this.shopsService.findByOwner(ownerId);
    if (!shop) throw new NotFoundException('Shop not found');
    return shop;
  }

  @Get()
  @ApiOperation({ summary: 'Get all shops with optional filters' })
  async getShops(
    @Query('category') category?: string,
    @Query('shopType') shopType?: string,
    @Query('search') search?: string,
  ) {
    return this.shopsService.findFiltered(category, shopType, search);
  }

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Shopkeeper', 'Admin')
  @ApiOperation({ summary: 'Create a new shop (Admin/Distributor only)' })
  async createShop(@Body() createShopDto: CreateShopDto) {
    return this.shopsService.create(createShopDto);
  }

  @Post('verify')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Upload shop verification documents to Cloudinary' })
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'gstCertificate', maxCount: 1 },
        { name: 'tradeLicense', maxCount: 1 },
        { name: 'shopImage', maxCount: 1 },
      ],
      {
        fileFilter: (req, file, callback) => {
          if (!file.originalname.match(/\.(jpg|jpeg|png|pdf)$/i)) {
            return callback(new BadRequestException('Only images and PDF files are allowed!'), false);
          }
          callback(null, true);
        },
      },
    ),
  )
  async verifyShop(
    @Req() req: any,
    @UploadedFiles()
    files: {
      gstCertificate?: Express.Multer.File[];
      tradeLicense?: Express.Multer.File[];
      shopImage?: Express.Multer.File[];
    },
    @Body() submitVerificationDto: SubmitVerificationDto,
  ) {
    const ownerId = req.user._id;

    if (!files || !files.gstCertificate || files.gstCertificate.length === 0) {
      throw new BadRequestException('GST Certificate file is required');
    }
    if (!files || !files.tradeLicense || files.tradeLicense.length === 0) {
      throw new BadRequestException('Trade License file is required');
    }
    if (!files || !files.shopImage || files.shopImage.length === 0) {
      throw new BadRequestException('Shop Front Image is required');
    }

    // Upload files to Cloudinary
    const [gstUrl, licenseUrl, shopImageUrl] = await Promise.all([
      this.cloudinaryService.uploadFile(files.gstCertificate[0]),
      this.cloudinaryService.uploadFile(files.tradeLicense[0]),
      this.cloudinaryService.uploadFile(files.shopImage[0]),
    ]);

    return this.shopsService.submitVerification(ownerId, submitVerificationDto, {
      gstCertificateUrl: gstUrl,
      tradeLicenseUrl: licenseUrl,
      shopImageUrl,
    });
  }

  @Get('admin/fix-status')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Admin')
  @ApiOperation({ summary: 'Fix status of all shops in database' })
  async fixStatus() {
    return this.shopsService.fixStatus();
  }

  @Get('admin/all')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Admin')
  @ApiOperation({ summary: 'Get all shops with populated owner details (Admin only)' })
  async getShopsAdmin() {
    return this.shopsService.findAllAdmin();
  }

  @Post('admin/:id/verify')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Admin')
  @ApiOperation({ summary: 'Verify or reject a shop verification request (Admin only)' })
  async verifyShopAdmin(
    @Param('id') id: string,
    @Body() body: { status: string; reason?: string; notes?: string },
  ) {
    if (!['Verified', 'Rejected', 'Pending', 'Unverified', 'Under Review', 'Changes Requested'].includes(body.status)) {
      throw new BadRequestException('Invalid verification status');
    }
    return this.shopsService.updateVerificationStatus(id, body.status, body.reason, body.notes);
  }

  @Put('my/status')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Shopkeeper', 'Admin')
  @ApiOperation({ summary: "Update current user's shop status (Open/Closed)" })
  async updateStatus(@Req() req: any, @Body() body: { status: string }) {
    const ownerId = req.user._id;
    if (!['Open', 'Closed'].includes(body.status)) {
      throw new BadRequestException('Invalid status value');
    }
    return this.shopsService.updateStatus(ownerId, body.status);
  }
}
